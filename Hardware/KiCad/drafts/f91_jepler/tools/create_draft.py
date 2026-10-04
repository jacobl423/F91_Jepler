#!/usr/bin/env python3
"""Create the initial editable design, NOT a fabrication output.
Run with KiCad's Python. Requires the imported Nordic config6 reference in build/.
This generator overwrites the initial draft; do not rerun after manual CAD edits.
"""
import json, re, uuid, pathlib, csv, copy, subprocess
import xml.etree.ElementTree as ET
import pcbnew as pcb
ROOT = pathlib.Path(__file__).resolve().parents[5]
OUT = pathlib.Path(__file__).resolve().parents[1]
LIB = pathlib.Path('/Applications/KiCad/KiCad.app/Contents/SharedSupport')
uid = lambda: str(uuid.uuid4())
q = lambda s: json.dumps(str(s), ensure_ascii=False)

class Atom(str): pass

def parse(text):
    tokens = iter(re.findall(r'"(?:\\.|[^"\\])*"|[()]|[^\s()]+', text))
    def item(t):
        if t == '(':
            a=[]
            for t in tokens:
                if t == ')': return a
                a.append(item(t))
        return json.loads(t) if t.startswith('"') else Atom(t)
    return item(next(tokens))
def sexp(v):
    return '('+' '.join(sexp(x) for x in v)+')' if isinstance(v,list) else (str(v) if isinstance(v,Atom) else q(v))
def children(v, name): return [x for x in v if isinstance(x,list) and x[0]==name]
def child(v, name): return children(v,name)[0]
cache={}
def symbol(libid):
    if libid in cache:return cache[libid]
    lib,name=libid.split(':')
    tree=parse((LIB/'symbols'/f'{lib}.kicad_sym').read_text())
    sym=next(x for x in children(tree,'symbol') if x[1]==name)
    if children(sym,'extends'):
        parent=symbol(lib+':'+child(sym,'extends')[1])
        body=copy.deepcopy(parent)
        body[1]=libid
        for s in children(body,'symbol'): s[1]=s[1].replace(child(sym,'extends')[1],name)
        for prop in children(sym,'property'):
            body=[x for x in body if not (isinstance(x,list) and x[0]=='property' and x[1]==prop[1])]
            body.append(prop)
        sym=body
    sym[1]=libid
    cache[libid]=sym
    return sym

def pins(s):
    return [p for sub in children(s,'symbol') for p in children(sub,'pin')]
ref=pcb.LoadBoard(str(ROOT/'build/hardware-reference/nordic-config6.kicad_pcb'))
parts=[]
capfp='Capacitor_SMD:C_0402_1005Metric'
for f in ref.GetFootprints():
    r=f.GetReference()
    if not r:continue
    nets={p.GetNumber():p.GetNetname() for p in f.Pads()}
    if r=='U1':
        nets['EP']=nets.pop('74'); libid='MCU_Nordic:nRF52840'; fp='Package_DFN_QFN:Nordic_AQFN-73-1EP_7x7mm_P0.5mm'
    elif r.startswith('C'):libid='Device:C';fp=capfp
    elif r=='L1':libid='Device:L';fp='Inductor_SMD:L_0402_1005Metric'
    elif r=='X1':libid='Device:Crystal_GND24';fp='Crystal:Crystal_SMD_2016-4Pin_2.0x1.6mm'
    elif r=='X2':libid='Device:Crystal';fp='Crystal:Crystal_SMD_3215-2Pin_3.2x1.5mm'
    else:raise ValueError(r)
    val=f.GetValue()
    if r in ('C17','C18'):val='9pF provisional'
    if r=='X2':val='ABS07-32.768KHZ-7-T'
    parts.append(dict(ref=r,value=val,libid=libid,fp=fp,nets=nets,
        pcb=(pcb.ToMM(f.GetPosition().x)-47.5011,pcb.ToMM(f.GetPosition().y)-5.0036),
        angle=f.GetOrientationDegrees(),dnp=val=='N.C.'))

def add(r,v,lib,fp,nets,xy,angle=0):
    parts.append(dict(ref=r,value=v,libid=lib,fp=fp,nets=nets,pcb=xy,angle=angle,dnp=False))
add('U2','TPS78230DDC','Regulator_Linear:TPS78230DDC','Package_TO_SOT_SMD:TSOT-23-5',{'1':'VBAT_PROTECTED','2':'GND','3':'VBAT_PROTECTED','4':'GND','5':'VDD_NRF'},(100,108))
add('C30','1uF','Device:C',capfp,{'1':'VBAT_PROTECTED','2':'GND'},(97,108))
add('C31','1uF','Device:C',capfp,{'1':'VDD_NRF','2':'GND'},(103,108))
# Individual test pads deliberately avoid inventing a connector or bracket footprint.
padfp='TestPoint:TestPoint_Pad_D1.0mm'
contacts=[('TP1','BAT+','VBAT_PROTECTED',(94,108)),('TP2','BAT-','GND',(94,110)),
 ('TP3','A / key 1','P0.11',(89,95)),('TP4','B / key 2','P0.12',(89,107)),
 ('TP5','C / key 3','P0.24',(111,107)),('TP6','SWDIO','SWDIO',(97,110)),
 ('TP7','SWDCLK','SWDCLK',(99,110)),('TP8','RESET','P0.18/RESET',(101,110)),
 ('TP9','GND','GND',(103,110)),('TP10','3V0','VDD_NRF',(105,110)),
 ('TP11','OLED SCL','P0.27',(95,91)),('TP12','OLED SDA','P0.26',(97,91)),
 ('TP13','OLED 3V0','VDD_NRF',(99,91)),('TP14','OLED GND','GND',(101,91)),
 ('TP15','RF feed / no antenna','RF',(110,99)),
 ('TP16','BUTTON COMMON proposed GND','GND',(111,109))]
for r,v,n,pos in contacts:add(r,v,'Connector:TestPoint',padfp,{'1':n},pos)

# Unused GPIOs are explicit no-connects, not misleading single-ended nets.
counts={}
for p in parts:
    for n in p['nets'].values(): counts[n]=counts.get(n,0)+1
for p in parts:
    p['nets']={k:('' if n.startswith('P') and counts[n]==1 else n) for k,n in p['nets'].items()}

# Generate schematic from embedded standard symbols; every PCB net is represented.
rootuid=uid();sch=[]
def note(text,x,y,size=1.5):
    sch.append(f'(text {q(text)} (at {x} {y} 0) (effects (font (size {size} {size})) (justify left bottom)) (uuid {q(uid())}))')
positions={'U1':(73.66,109.22),'U2':(292.10,48.26),'X1':(177.8,43.18),'X2':(177.8,71.12),'L1':(177.8,99.06),'C30':(271.78,76.2),'C31':(302.26,76.2)}
caps=sorted([p for p in parts if p['ref'].startswith('C') and p['ref'] not in positions],key=lambda p:int(p['ref'][1:]))
for i,p in enumerate(caps): positions[p['ref']]=(152.4+(i%3)*35.56,134.62+(i//3)*22.86)
for i,p in enumerate([p for p in parts if p['ref'].startswith('TP')]):positions[p['ref']]=(279.4+(i%2)*66.04,114.3+(i//2)*15.24)
for p in parts:
    s=symbol(p['libid']); x,y=positions[p['ref']]; p['uuid']=uid()
    if p['ref'].startswith(('C','L')):
        prop_x,prop_y=x+7.62,y-1.27
    elif p['ref']=='U1': prop_x,prop_y=x,y
    else: prop_x,prop_y=x,y-7.62
    props=''.join(f'(property {q(k)} {q(v)} (at {prop_x} {prop_y+off} 0) (effects (font (size 1.0 1.0)){hide}))' for k,v,off,hide in [('Reference',p['ref'],0,''),('Value',p['value'],2.54,''),('Footprint',p['fp'],0,' hide')])
    sch.append(f'(symbol (lib_id {q(p["libid"])}) (at {x} {y} 0) (unit 1) (in_bom {"no" if p["ref"].startswith("TP") else "yes"}) (on_board yes) (dnp {"yes" if p["dnp"] else "no"}) (uuid {q(p["uuid"])}) {props} (instances (project "f91_jepler" (path {q("/"+rootuid)} (reference {q(p["ref"])}) (unit 1)))))')
    for pin in pins(s):
        num=child(pin,'number')[1]; a=child(pin,'at'); px=x+float(a[1]);py=y-float(a[2]);net=p['nets'].get(num,'')
        if net:
            # A short wire keeps net names clear of pin numbers and symbol bodies.
            ang=int(float(a[3])); dx,dy={0:(-5.08,0),180:(5.08,0),90:(0,5.08),270:(0,-5.08)}[ang]
            ex,ey=round(px+dx,4),round(py+dy,4)
            sch.append(f'(wire (pts (xy {px} {py}) (xy {ex} {ey})) (stroke (width 0) (type default)) (uuid {q(uid())}))')
            la={0:180,180:0,90:270,270:90}[ang]
            if p["ref"]!="U1" and ang in (90,270):la=0
            sch.append(f'(label {q(net)} (at {ex} {ey} {la}) (effects (font (size 0.9 0.9)) (justify left bottom)) (uuid {q(uid())}))')
        else:sch.append(f'(no_connect (at {px} {py}) (uuid {q(uid())}))')
# External protected battery provides power to VBAT and ground; these flags only
# describe the schematic source, not cell protection or charger implementation.
for net,x,y in [('VBAT_PROTECTED',330.2,48.26),('GND',355.6,48.26)]:
    libid='power:PWR_FLAG';symbol(libid); flagid=uid()
    sch.append(f'(symbol (lib_id "power:PWR_FLAG") (at {x} {y} 0) (unit 1) (in_bom no) (on_board yes) (dnp no) (uuid {q(flagid)}) (property "Reference" "#FLG{int(x)}" (at {x} {y} 0) (effects (font (size 1 1)) hide)) (property "Value" "PWR_FLAG" (at {x} {y-5.08} 0) (effects (font (size 1 1))))) (label {q(net)} (at {x} {y} 0) (effects (font (size 0.9 0.9)) (justify left bottom)) (uuid {q(uid())}))')
note('F91 JEPLER / REV A0 — ELECTRICAL AND PLACEMENT DRAFT',20,15,2)
note('NOT FOR FABRICATION — battery, bracket, antenna and OLED interface unresolved',20,23)
note('Nordic config 6: VDD supply, LDO only, no USB. Firmware must keep DC/DC disabled.',20,255)
note('3.0 V regulated supply / protected 1S LiPo input',257,30)
note('No onboard charger captured yet. BQ25100 + charge/load isolation pending.',257,91,1.1)
note('Contact pads are NOT verified bracket or OLED footprints.',257,99,1.1)
note('LF load capacitors provisional; HF crystal exact MPN pending.',140,116,1.1)
note('RF matching reference only: antenna and final layout require tuning.',140,122,1.1)
note('C9: 820pF for pre-Fxx MCU; omit for Fxx and later after BOM selection.',20,263,1.1)
note('Unused GPIOs intentionally marked no-connect. Buttons propose active-low to GND.',20,270,1.1)
content=f'(kicad_sch (version 20250114) (generator "eeschema") (uuid {q(rootuid)}) (paper "A3") (title_block (title "F91 Jepler — provisional core") (date "2026-10-03") (rev "A0") (comment 1 "UNROUTED DRAFT — NOT FOR FABRICATION")) (lib_symbols {" ".join(sexp(s) for s in cache.values())}) {" ".join(sch)})'
(OUT/'f91_jepler.kicad_sch').write_text(content)

# Let KiCad name local and no-connect nets, then use that exact netlist for PCB.
netfile=ROOT/'build/hardware-reference/draft.net.xml'
subprocess.run([str(LIB.parent/'MacOS/kicad-cli'),'sch','export','netlist','--format','kicadxml','-o',str(netfile),str(OUT/'f91_jepler.kicad_sch')],check=True)
netroot=ET.parse(netfile)
byref={p['ref']:p for p in parts}
for p in parts:p['nets']={}
for net in netroot.findall('./nets/net'):
    for node in net.findall('node'):
        if node.get('ref') in byref:byref[node.get('ref')]['nets'][node.get('pin')]=net.get('name')[:1]+net.get('name')[1:].replace('/', '{slash}')
placements={'X1':(104,92.7),'C1':(106.3,92.7),'C2':(101.7,92.7),
 'X2':(92.5,98.5),'C17':(90.5,96.2),'C18':(93.3,96.2),'C5':(94,101),
 'C14':(94.5,94),'C15':(97,94),'C12':(106,95.5),'C13':(100,94),
 'C3':(105.7,99),'L1':(107.5,99),'C4':(109.2,99),'C22':(110.5,101),
 'TP15':(110.5,97),'C7':(100.3,105.8),'C8':(103,105.8),'C9':(106,102.5),
 'C10':(105.7,101),'C11':(106,97.2),'C6':(94.5,104.5),
 'TP7':(106.5,108),'TP8':(108.5,108),'TP14':(101,89.8)}
for p in parts:
    if p['ref'] in placements:p['pcb']=placements[p['ref']]
    if p['ref'] in ['C7','C8']:p['angle']=0
board=pcb.BOARD(); board.SetCopperLayerCount(4)
board.GetDesignSettings().SetBoardThickness(pcb.FromMM(0.8))
netmap={}
for n in sorted({n for p in parts for n in p['nets'].values() if n}):
    net=pcb.NETINFO_ITEM(board,n);board.Add(net);netmap[n]=net
for p in parts:
    lib,name=p['fp'].split(':'); f=pcb.FootprintLoad(str(LIB/'footprints'/f'{lib}.pretty'),name)
    if f is None:raise RuntimeError(p['fp'])
    f.SetReference(p['ref']);f.SetValue(p['value']);f.SetFPID(pcb.LIB_ID(lib,name));f.SetPosition(pcb.VECTOR2I(*[pcb.FromMM(n) for n in p['pcb']]))
    f.SetOrientationDegrees(p['angle']);f.SetDNP(p['dnp'])
    path=pcb.KIID_PATH();path.push_back(pcb.KIID(rootuid));path.push_back(pcb.KIID(p['uuid']));f.SetPath(path)
    for pad in f.Pads():
        n=p['nets'].get(pad.GetNumber(),'')
        if n:pad.SetNet(netmap[n])
    f.Value().SetVisible(False);f.Reference().SetLayer(pcb.F_Fab);board.Add(f)

def line(a,b,layer,width=.15):
    sh=pcb.PCB_SHAPE();sh.SetShape(pcb.SHAPE_T_SEGMENT);sh.SetStart(pcb.VECTOR2I(*[pcb.FromMM(n) for n in a]));sh.SetEnd(pcb.VECTOR2I(*[pcb.FromMM(n) for n in b]));sh.SetLayer(layer);sh.SetWidth(pcb.FromMM(width));board.Add(sh)
def box(x0,y0,x1,y1,layer):
    pts=[(x0,y0),(x1,y0),(x1,y1),(x0,y1)]
    for a,b in zip(pts,pts[1:]+pts[:1]):line(a,b,layer)
def text(t,x,y,layer=pcb.Dwgs_User,size=.8):
    o=pcb.PCB_TEXT(board);o.SetText(t);o.SetPosition(pcb.VECTOR2I(pcb.FromMM(x),pcb.FromMM(y)));o.SetTextSize(pcb.VECTOR2I(pcb.FromMM(size),pcb.FromMM(size)));o.SetTextThickness(pcb.FromMM(.12));o.SetLayer(layer);board.Add(o)
# 24 x 23.5 mm is a planning envelope, NOT an STL-derived mating outline.
outline=[(90,88.25),(110,88.25),(112,90.25),(112,109.75),(110,111.75),(90,111.75),(88,109.75),(88,90.25)]
for a,b in zip(outline,outline[1:]+outline[:1]):line(a,b,pcb.Edge_Cuts,.05)
box(92,94,108,106,pcb.Dwgs_User)
text('REAR BATTERY SPACE STUDY ONLY\n16 x 12 mm; thickness TBD\nInsulation + swelling allowance TBD',100,100,size=.65)
text('BRACKET / SPRING CONTACTS UNMEASURED',100,86,size=.75)
text('A0 — UNROUTED — DO NOT FABRICATE',100,114,size=.8)
text('24 x 23.5 mm provisional outline / 0.8 mm provisional PCB',100,116,size=.65)
text('A/1',89.6,93,pcb.F_SilkS,.8);text('B/2',89.6,105,pcb.F_SilkS,.8);text('C/3',110.4,105,pcb.F_SilkS,.8)
# No traces: package replacements and final mechanical constraints need fresh layout.
pcb.SaveBoard(str(OUT/'f91_jepler.kicad_pcb'),board)
(OUT/'f91_jepler.kicad_pro').write_text(json.dumps({'meta':{'filename':'f91_jepler.kicad_pro','version':1},'board':{'design_settings':{'rules':{'min_clearance':0.1,'min_track_width':0.1}}}},indent=2)+'\n')
with (OUT/'components.csv').open('w') as f:
    w=csv.writer(f, lineterminator="\n");w.writerow(['Reference','Value','Footprint','DNP','Status']);w.writerows((p['ref'],p['value'],p['fp'],p['dnp'],'DRAFT - not purchasing BOM') for p in parts)
print(f'Created {len(parts)} components, {len(netmap)} nets; no routes.')
