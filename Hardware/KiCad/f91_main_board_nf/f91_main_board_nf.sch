<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE eagle SYSTEM "eagle.dtd">
<eagle version="7.5.0">
<drawing>
<settings>
<setting alwaysvectorfont="no"/>
<setting verticaltext="up"/>
</settings>
<grid distance="0.1" unitdist="inch" unit="mil" style="lines" multiple="1" display="yes" altdistance="0.01" altunitdist="inch" altunit="inch"/>
<layers>
<layer number="1" name="Top" color="4" fill="1" visible="no" active="no"/>
<layer number="2" name="Route2" color="1" fill="3" visible="no" active="no"/>
<layer number="3" name="Route3" color="4" fill="3" visible="no" active="no"/>
<layer number="4" name="Route4" color="1" fill="4" visible="no" active="no"/>
<layer number="5" name="Route5" color="4" fill="4" visible="no" active="no"/>
<layer number="6" name="Route6" color="1" fill="8" visible="no" active="no"/>
<layer number="7" name="Route7" color="4" fill="8" visible="no" active="no"/>
<layer number="8" name="Route8" color="1" fill="2" visible="no" active="no"/>
<layer number="9" name="Route9" color="4" fill="2" visible="no" active="no"/>
<layer number="10" name="Route10" color="1" fill="7" visible="no" active="no"/>
<layer number="11" name="Route11" color="4" fill="7" visible="no" active="no"/>
<layer number="12" name="Route12" color="1" fill="5" visible="no" active="no"/>
<layer number="13" name="Route13" color="4" fill="5" visible="no" active="no"/>
<layer number="14" name="Route14" color="1" fill="6" visible="no" active="no"/>
<layer number="15" name="Route15" color="4" fill="6" visible="no" active="no"/>
<layer number="16" name="Bottom" color="1" fill="1" visible="no" active="no"/>
<layer number="17" name="Pads" color="2" fill="1" visible="no" active="no"/>
<layer number="18" name="Vias" color="2" fill="1" visible="no" active="no"/>
<layer number="19" name="Unrouted" color="6" fill="1" visible="no" active="no"/>
<layer number="20" name="Dimension" color="15" fill="1" visible="no" active="no"/>
<layer number="21" name="tPlace" color="7" fill="1" visible="no" active="no"/>
<layer number="22" name="bPlace" color="7" fill="1" visible="no" active="no"/>
<layer number="23" name="tOrigins" color="15" fill="1" visible="no" active="no"/>
<layer number="24" name="bOrigins" color="15" fill="1" visible="no" active="no"/>
<layer number="25" name="tNames" color="7" fill="1" visible="no" active="no"/>
<layer number="26" name="bNames" color="7" fill="1" visible="no" active="no"/>
<layer number="27" name="tValues" color="7" fill="1" visible="no" active="no"/>
<layer number="28" name="bValues" color="7" fill="1" visible="no" active="no"/>
<layer number="29" name="tStop" color="7" fill="3" visible="no" active="no"/>
<layer number="30" name="bStop" color="7" fill="6" visible="no" active="no"/>
<layer number="31" name="tCream" color="7" fill="4" visible="no" active="no"/>
<layer number="32" name="bCream" color="7" fill="5" visible="no" active="no"/>
<layer number="33" name="tFinish" color="6" fill="3" visible="no" active="no"/>
<layer number="34" name="bFinish" color="6" fill="6" visible="no" active="no"/>
<layer number="35" name="tGlue" color="7" fill="4" visible="no" active="no"/>
<layer number="36" name="bGlue" color="7" fill="5" visible="no" active="no"/>
<layer number="37" name="tTest" color="7" fill="1" visible="no" active="no"/>
<layer number="38" name="bTest" color="7" fill="1" visible="no" active="no"/>
<layer number="39" name="tKeepout" color="4" fill="11" visible="no" active="no"/>
<layer number="40" name="bKeepout" color="1" fill="11" visible="no" active="no"/>
<layer number="41" name="tRestrict" color="4" fill="10" visible="no" active="no"/>
<layer number="42" name="bRestrict" color="1" fill="10" visible="no" active="no"/>
<layer number="43" name="vRestrict" color="2" fill="10" visible="no" active="no"/>
<layer number="44" name="Drills" color="7" fill="1" visible="no" active="no"/>
<layer number="45" name="Holes" color="7" fill="1" visible="no" active="no"/>
<layer number="46" name="Milling" color="3" fill="1" visible="yes" active="no"/>
<layer number="47" name="Measures" color="7" fill="1" visible="no" active="no"/>
<layer number="48" name="Document" color="7" fill="1" visible="no" active="no"/>
<layer number="49" name="Reference" color="7" fill="1" visible="no" active="no"/>
<layer number="51" name="tDocu" color="7" fill="1" visible="no" active="no"/>
<layer number="52" name="bDocu" color="7" fill="1" visible="no" active="no"/>
<layer number="90" name="Modules" color="5" fill="1" visible="yes" active="yes"/>
<layer number="91" name="Nets" color="2" fill="1" visible="yes" active="yes"/>
<layer number="92" name="Busses" color="1" fill="1" visible="yes" active="yes"/>
<layer number="93" name="Pins" color="2" fill="1" visible="no" active="yes"/>
<layer number="94" name="Symbols" color="4" fill="1" visible="yes" active="yes"/>
<layer number="95" name="Names" color="7" fill="1" visible="yes" active="yes"/>
<layer number="96" name="Values" color="7" fill="1" visible="yes" active="yes"/>
<layer number="97" name="Info" color="7" fill="1" visible="yes" active="yes"/>
<layer number="98" name="Guide" color="6" fill="1" visible="yes" active="yes"/>
</layers>
<schematic xreflabel="%F%N/%S.%C%R" xrefpart="/%S.%C%R">
<attributes/>
<variantdefs/>
<libraries>
<library name="common">
<packages>
<package name="SINGLE_PROBE_POINT">
<smd name="1" x="0.013" y="-0.002" layer="1" dx="0.7" dy="0.7" roundness="100" rot="R0" stop="yes" cream="yes" thermals="no"/>
<dimension x1="0.013" y1="0.348" x2="0.013" y2="-0.352" x3="1.842" y3="0.348" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="FC-135">
<smd name="1" x="0.67" y="1.05" layer="1" dx="1" dy="1.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="3.17" y="1.05" layer="1" dx="1" dy="1.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<wire layer="21" width="0.05" x1="1.22" y1="1.98" x2="2.63" y2="1.98"/>
<wire layer="21" width="0.05" x1="2.63" y1="1.98" x2="2.63" y2="0.12"/>
<wire layer="21" width="0.05" x1="2.63" y1="0.12" x2="1.22" y2="0.12"/>
<wire layer="21" width="0.05" x1="1.22" y1="0.12" x2="1.22" y2="1.98"/>
<wire layer="21" width="0.05" x1="1.74" y1="1.6" x2="2.11" y2="1.6"/>
<wire layer="21" width="0.05" x1="2.11" y1="1.6" x2="2.11" y2="0.51"/>
<wire layer="21" width="0.05" x1="2.11" y1="0.51" x2="1.74" y2="0.51"/>
<wire layer="21" width="0.05" x1="1.74" y1="0.51" x2="1.74" y2="1.6"/>
<wire layer="21" width="0.05" x1="1.59" y1="1.6" x2="1.59" y2="0.51"/>
<wire layer="21" width="0.05" x1="2.26" y1="1.6" x2="2.26" y2="0.51"/>
<wire layer="21" width="0.05" x1="1.59" y1="1.1" x2="1.31" y2="1.1"/>
<wire layer="21" width="0.05" x1="2.54" y1="1.09" x2="2.28" y2="1.09"/>
<polygon layer="21" width="0.25">
<vertex x="-0.255" y="0.895"/>
<vertex x="-0.283" y="0.897"/>
<vertex x="-0.311" y="0.904"/>
<vertex x="-0.337" y="0.915"/>
<vertex x="-0.361" y="0.929"/>
<vertex x="-0.382" y="0.948"/>
<vertex x="-0.401" y="0.969"/>
<vertex x="-0.415" y="0.993"/>
<vertex x="-0.426" y="1.019"/>
<vertex x="-0.433" y="1.047"/>
<vertex x="-0.435" y="1.075"/>
<vertex x="-0.433" y="1.103"/>
<vertex x="-0.426" y="1.131"/>
<vertex x="-0.415" y="1.157"/>
<vertex x="-0.401" y="1.181"/>
<vertex x="-0.382" y="1.202"/>
<vertex x="-0.361" y="1.221"/>
<vertex x="-0.337" y="1.235"/>
<vertex x="-0.311" y="1.246"/>
<vertex x="-0.283" y="1.253"/>
<vertex x="-0.255" y="1.255"/>
<vertex x="-0.245" y="1.255"/>
<vertex x="-0.217" y="1.253"/>
<vertex x="-0.189" y="1.246"/>
<vertex x="-0.163" y="1.235"/>
<vertex x="-0.139" y="1.221"/>
<vertex x="-0.118" y="1.202"/>
<vertex x="-0.099" y="1.181"/>
<vertex x="-0.084" y="1.157"/>
<vertex x="-0.074" y="1.131"/>
<vertex x="-0.067" y="1.103"/>
<vertex x="-0.065" y="1.075"/>
<vertex x="-0.067" y="1.047"/>
<vertex x="-0.074" y="1.019"/>
<vertex x="-0.084" y="0.993"/>
<vertex x="-0.099" y="0.969"/>
<vertex x="-0.118" y="0.948"/>
<vertex x="-0.139" y="0.929"/>
<vertex x="-0.163" y="0.915"/>
<vertex x="-0.189" y="0.904"/>
<vertex x="-0.217" y="0.897"/>
<vertex x="-0.245" y="0.895"/>
</polygon>
<dimension x1="0.67" y1="1.05" x2="3.17" y2="1.05" x3="0.67" y3="4" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="CAP_0603">
<description>Description: non polarized</description>
<smd name="1" x="-0.82" y="0" layer="1" dx="1" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.82" y="0" layer="1" dx="1" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<dimension x1="-0.82" y1="0.5" x2="-0.82" y2="-0.5" x3="-2.21" y3="0.5" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-0.82" y1="0" x2="0.82" y2="0" x3="-0.82" y3="1.44" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="IND_0805">
<description>Standard EIA: 0805
Standard METRIC: 2012</description>
<smd name="1" x="-0.85" y="0" layer="1" dx="1.45" dy="1.2" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.85" y="0" layer="1" dx="1.45" dy="1.2" rot="R90" stop="yes" cream="yes" thermals="no"/>
</package>
<package name="CAP_0402">
<description>Description: non polarized</description>
<smd name="1" x="-0.51" y="-0.03" layer="1" dx="0.7" dy="0.6" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.49" y="-0.03" layer="1" dx="0.7" dy="0.6" rot="R90" stop="yes" cream="yes" thermals="no"/>
<dimension x1="0.49" y1="-0.03" x2="-0.51" y2="-0.03" x3="0.49" y3="1.27" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-0.51" y1="0.32" x2="-0.51" y2="-0.38" x3="-2.55" y3="0.32" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="IND_0402">
<description>Standard EIA: 0402
Standard METRIC: 1005</description>
<smd name="1" x="-0.48" y="0" layer="1" dx="0.7" dy="0.6" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.48" y="0" layer="1" dx="0.7" dy="0.6" rot="R90" stop="yes" cream="yes" thermals="no"/>
<dimension x1="-0.48" y1="0" x2="0.48" y2="0" x3="-0.48" y3="1.19" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="RES_0402">
<smd name="1" x="-0.66" y="0.01" layer="1" dx="0.7" dy="0.6" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.34" y="0.01" layer="1" dx="0.7" dy="0.6" rot="R90" stop="yes" cream="yes" thermals="no"/>
<dimension x1="-0.96" y1="0.01" x2="-0.36" y2="0.01" x3="-0.96" y3="1.5" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-0.66" y1="0.36" x2="-0.66" y2="-0.34" x3="-2.12" y3="0.36" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-0.66" y1="0.01" x2="0.34" y2="0.01" x3="-0.66" y3="-0.88" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="SINGLECONNECT">
<smd name="1" x="0" y="-0.02" layer="1" dx="0.7" dy="0.6" rot="R0" stop="yes" cream="yes" thermals="no"/>
</package>
<package name="RGZ0048A-VQFN-48(LONGER_PADS)">
<smd name="49" x="0.01" y="0" layer="1" dx="5.15" dy="5.15" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="1" x="-3.39" y="2.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="-3.39" y="2.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="3" x="-3.39" y="1.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="4" x="-3.39" y="1.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="5" x="-3.39" y="0.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="6" x="-3.39" y="0.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="7" x="-3.39" y="-0.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="8" x="-3.39" y="-0.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="9" x="-3.39" y="-1.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="10" x="-3.39" y="-1.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="11" x="-3.39" y="-2.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="12" x="-3.39" y="-2.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="13" x="-2.74" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="14" x="-2.24" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="15" x="-1.74" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="16" x="-1.24" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="17" x="-0.74" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="18" x="-0.24" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="19" x="0.26" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="20" x="0.76" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="21" x="1.26" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="22" x="1.76" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="23" x="2.26" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="24" x="2.76" y="-3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="25" x="3.41" y="-2.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="26" x="3.41" y="-2.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="27" x="3.41" y="-1.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="28" x="3.41" y="-1.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="29" x="3.41" y="-0.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="30" x="3.41" y="-0.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="31" x="3.41" y="0.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="32" x="3.41" y="0.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="33" x="3.41" y="1.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="34" x="3.41" y="1.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="35" x="3.41" y="2.25" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="36" x="3.41" y="2.75" layer="1" dx="0.24" dy="0.8" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="37" x="2.76" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="38" x="2.26" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="39" x="1.76" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="40" x="1.26" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="41" x="0.76" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="42" x="0.26" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="43" x="-0.24" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="44" x="-0.74" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="45" x="-1.24" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="46" x="-1.74" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="47" x="-2.24" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="48" x="-2.74" y="3.4" layer="1" dx="0.24" dy="0.8" rot="R0" stop="yes" cream="yes" thermals="no"/>
<wire layer="21" width="0.25" x1="-2.81" y1="2.84" x2="2.84" y2="2.84"/>
<wire layer="21" width="0.25" x1="2.84" y1="2.84" x2="2.84" y2="-2.84"/>
<wire layer="21" width="0.25" x1="2.84" y1="-2.84" x2="-2.81" y2="-2.84"/>
<wire layer="21" width="0.25" x1="-2.81" y1="-2.84" x2="-2.81" y2="2.84"/>
<circle layer="21" x="-4.3" y="2.75" radius="0.3" width="0"/>
<dimension x1="-3.79" y1="2.75" x2="-2.99" y2="2.75" x3="-3.79" y3="5.89" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-2.74" y1="3.4" x2="-2.24" y2="3.4" x3="-2.74" y3="4.47" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="2.88" y1="3.4" x2="2.88" y2="-3.4" x3="5.48" y3="3.4" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-3.39" y1="-2.87" x2="3.41" y2="-2.87" x3="-3.39" y3="-6.93" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="CAP_0603_31">
<description>Description: non polarized</description>
<smd name="1" x="-0.85" y="0" layer="1" dx="1" dy="1.1" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.85" y="0" layer="1" dx="1" dy="1.1" rot="R90" stop="yes" cream="yes" thermals="no"/>
</package>
<package name="TSX-3225">
<smd name="1" x="0.92" y="0.73" layer="1" dx="1.4" dy="1.15" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="3.12" y="0.73" layer="1" dx="1.4" dy="1.15" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="3" x="3.12" y="2.33" layer="1" dx="1.4" dy="1.15" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="4" x="0.92" y="2.33" layer="1" dx="1.4" dy="1.15" rot="R0" stop="yes" cream="yes" thermals="no"/>
<wire layer="21" width="0.25" x1="-0.13" y1="3.24" x2="4.22" y2="3.24"/>
<wire layer="21" width="0.25" x1="4.22" y1="3.24" x2="4.22" y2="-0.14"/>
<wire layer="21" width="0.25" x1="4.22" y1="-0.14" x2="-0.13" y2="-0.14"/>
<wire layer="21" width="0.25" x1="-0.13" y1="-0.14" x2="-0.13" y2="3.24"/>
<polygon layer="21" width="0.25">
<vertex x="0.725" y="-0.69"/>
<vertex x="0.728" y="-0.656"/>
<vertex x="0.735" y="-0.624"/>
<vertex x="0.748" y="-0.592"/>
<vertex x="0.766" y="-0.564"/>
<vertex x="0.788" y="-0.538"/>
<vertex x="0.814" y="-0.516"/>
<vertex x="0.842" y="-0.498"/>
<vertex x="0.873" y="-0.486"/>
<vertex x="0.906" y="-0.478"/>
<vertex x="0.94" y="-0.475"/>
<vertex x="0.974" y="-0.478"/>
<vertex x="1.006" y="-0.486"/>
<vertex x="1.037" y="-0.498"/>
<vertex x="1.066" y="-0.516"/>
<vertex x="1.092" y="-0.538"/>
<vertex x="1.114" y="-0.564"/>
<vertex x="1.131" y="-0.592"/>
<vertex x="1.144" y="-0.624"/>
<vertex x="1.152" y="-0.656"/>
<vertex x="1.155" y="-0.69"/>
<vertex x="1.155" y="-0.7"/>
<vertex x="1.152" y="-0.734"/>
<vertex x="1.144" y="-0.766"/>
<vertex x="1.131" y="-0.798"/>
<vertex x="1.114" y="-0.826"/>
<vertex x="1.092" y="-0.852"/>
<vertex x="1.066" y="-0.874"/>
<vertex x="1.037" y="-0.892"/>
<vertex x="1.006" y="-0.904"/>
<vertex x="0.974" y="-0.912"/>
<vertex x="0.94" y="-0.915"/>
<vertex x="0.906" y="-0.912"/>
<vertex x="0.873" y="-0.904"/>
<vertex x="0.842" y="-0.892"/>
<vertex x="0.814" y="-0.874"/>
<vertex x="0.788" y="-0.852"/>
<vertex x="0.766" y="-0.826"/>
<vertex x="0.748" y="-0.798"/>
<vertex x="0.735" y="-0.766"/>
<vertex x="0.728" y="-0.734"/>
<vertex x="0.725" y="-0.7"/>
</polygon>
<dimension x1="0.92" y1="2.33" x2="3.12" y2="2.33" x3="0.92" y3="3.98" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="3.12" y1="2.33" x2="3.12" y2="0.73" x3="5.62" y3="2.33" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="5050660622">
<smd name="0@_1" x="-1.63" y="0.465" layer="1" dx="0.4" dy="0.386" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="0@_2" x="-1.63" y="-0.501" layer="1" dx="0.4" dy="0.386" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="1" x="-0.35" y="0.982" layer="1" dx="0.18" dy="0.5" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0" y="0.982" layer="1" dx="0.18" dy="0.5" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="3" x="0.35" y="0.982" layer="1" dx="0.18" dy="0.5" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="4" x="-0.35" y="-1.018" layer="1" dx="0.18" dy="0.5" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="5" x="0" y="-1.018" layer="1" dx="0.18" dy="0.5" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="6" x="0.35" y="-1.018" layer="1" dx="0.18" dy="0.5" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="0@_3" x="1.63" y="0.465" layer="1" dx="0.4" dy="0.386" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="0@" x="1.63" y="-0.501" layer="1" dx="0.4" dy="0.386" rot="R0" stop="yes" cream="yes" thermals="no"/>
<wire layer="21" width="0.1" x1="-1.889" y1="1.306" x2="1.897" y2="1.306"/>
<wire layer="21" width="0.1" x1="1.897" y1="1.306" x2="1.897" y2="-1.33"/>
<wire layer="21" width="0.1" x1="1.897" y1="-1.33" x2="-1.889" y2="-1.33"/>
<wire layer="21" width="0.1" x1="-1.889" y1="-1.33" x2="-1.889" y2="1.306"/>
<dimension x1="-1.63" y1="0.272" x2="-1.63" y2="-0.308" x3="-3.376" y3="0.272" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="0.35" y1="0.732" x2="0.35" y2="-0.768" x3="4.079" y3="0.732" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-1.63" y1="0.465" x2="-0.35" y2="0.982" x3="-1.63" y3="2.832" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="0.35" y1="-1.018" x2="1.63" y2="-0.501" x3="0.35" y3="-2.968" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="0" y1="-1.018" x2="-0.35" y2="-1.018" x3="0" y3="-4.831" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="BT_ANTENNA">
<smd name="1" x="0.01" y="0.06" layer="1" dx="1" dy="1" rot="R0" stop="yes" cream="yes" thermals="no"/>
<dimension x1="-0.49" y1="0.06" x2="0.51" y2="0.06" x3="-0.49" y3="3.33" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
</packages>
<symbols>
<symbol name="WMCU_TCK">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="WMCU_TXD">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="WMCU_TXD_2_0">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="WMCU_TXD_3_0">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="DCDC_SW">
<wire layer="94" width="0.25" x1="-2.54" y1="0" x2="2.54" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="VCC" visible="pad" length="short" direction="sup" rot="R90" x="0" y="-2.54"/>
</symbol>
<symbol name="WMCU_TMS">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="WMCU_TMS_6_0">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="SW1">
<circle layer="94" x="-0.476" y="0" radius="0.794" width="0.25"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0.317" y2="0"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="SW1_8_0">
<circle layer="94" x="-0.476" y="0" radius="0.794" width="0.25"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0.317" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="FC-135">
<wire layer="94" width="0.25" x1="5.08" y1="5.08" x2="7.62" y2="5.08"/>
<wire layer="94" width="0.25" x1="7.62" y1="5.08" x2="7.62" y2="0"/>
<wire layer="94" width="0.25" x1="7.62" y1="0" x2="5.08" y2="0"/>
<wire layer="94" width="0.25" x1="5.08" y1="0" x2="5.08" y2="5.08"/>
<wire layer="94" width="0.25" x1="8.89" y1="5.08" x2="8.89" y2="0"/>
<wire layer="94" width="0.25" x1="3.81" y1="5.08" x2="3.81" y2="0"/>
<text x="6.35" y="5.663" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<text x="6.35" y="-0.612" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="top-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="nc" x="1.27" y="2.54"/>
<pin name="2" visible="pad" length="short" direction="nc" rot="R180" x="11.43" y="2.54"/>
</symbol>
<symbol name="GND">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="GND_11_0">
<wire layer="94" width="0.25" x1="-1.905" y1="1.016" x2="1.905" y2="1.016"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-0.508" y1="-1.016" x2="0.508" y2="-1.016"/>
<text x="-2.488" y="0" size="1.619" layer="96" font="vector" ratio="10" rot="R90" align="bottom-center" distance="50">>VALUE</text>
<pin name="GND" visible="pad" length="short" direction="sup" rot="R270" x="0" y="3.556"/>
</symbol>
<symbol name="SDA">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="-1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="0" y1="-1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="1.27"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="SDA_13_0">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="-1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="0" y1="-1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="SWO">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="CAP_0603">
<wire layer="94" width="0.254" x1="0.944" y1="1.911" x2="0.944" y2="-1.911" curve="74.02156"/>
<wire layer="94" width="0.25" x1="-0.33" y1="-1.905" x2="-0.33" y2="1.905"/>
<wire layer="94" width="0.25" x1="0.305" y1="0" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="-0.33" y2="0"/>
<text x="0" y="2.494" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<text x="0" y="-2.522" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="top-center" distance="50">>VALUE</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="3.81" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-3.81" y="0"/>
</symbol>
<symbol name="IND_0805">
<wire layer="94" width="0.254" x1="5.08" y1="0" x2="2.54" y2="0" curve="180.01504"/>
<wire layer="94" width="0.254" x1="2.54" y1="0" x2="0" y2="0" curve="180.01504"/>
<wire layer="94" width="0.254" x1="0" y1="0" x2="-2.54" y2="0" curve="180.01504"/>
<wire layer="94" width="0.254" x1="-2.54" y1="0" x2="-5.08" y2="0" curve="180.01504"/>
<wire layer="94" width="0.25" x1="5.08" y1="-1.27" x2="5.08" y2="0"/>
<wire layer="94" width="0.25" x1="2.54" y1="-1.27" x2="2.54" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="-2.54" y1="-1.27" x2="-2.54" y2="0"/>
<wire layer="94" width="0.25" x1="-5.08" y1="-1.27" x2="-5.08" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<text x="0" y="-2.112" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="top-center" distance="50">>VALUE</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="7.62" y="-1.27"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-7.62" y="-1.27"/>
</symbol>
<symbol name="WMCU_RESET">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="WMCU_RESET_18_0">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="CAP_0402">
<wire layer="94" width="0.254" x1="0.944" y1="1.911" x2="0.944" y2="-1.911" curve="74.02156"/>
<wire layer="94" width="0.25" x1="-0.33" y1="-1.905" x2="-0.33" y2="1.905"/>
<wire layer="94" width="0.25" x1="0.305" y1="0" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="-0.33" y2="0"/>
<text x="0" y="2.494" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<text x="0" y="-2.522" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="top-center" distance="50">>VALUE</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="3.81" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-3.81" y="0"/>
</symbol>
<symbol name="CAP_0402_20_0">
<wire layer="94" width="0.254" x1="0.944" y1="1.911" x2="0.944" y2="-1.911" curve="74.02156"/>
<wire layer="94" width="0.25" x1="-0.33" y1="-1.905" x2="-0.33" y2="1.905"/>
<wire layer="94" width="0.25" x1="0.305" y1="0" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="-0.33" y2="0"/>
<text x="0" y="2.494" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="3.81" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-3.81" y="0"/>
</symbol>
<symbol name="IND_0402">
<wire layer="94" width="0.254" x1="5.08" y1="0" x2="2.54" y2="0" curve="180.01504"/>
<wire layer="94" width="0.254" x1="2.54" y1="0" x2="0" y2="0" curve="180.01504"/>
<wire layer="94" width="0.254" x1="0" y1="0" x2="-2.54" y2="0" curve="180.01504"/>
<wire layer="94" width="0.254" x1="-2.54" y1="0" x2="-5.08" y2="0" curve="180.01504"/>
<wire layer="94" width="0.25" x1="5.08" y1="-1.27" x2="5.08" y2="0"/>
<wire layer="94" width="0.25" x1="2.54" y1="-1.27" x2="2.54" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="-2.54" y1="-1.27" x2="-2.54" y2="0"/>
<wire layer="94" width="0.25" x1="-5.08" y1="-1.27" x2="-5.08" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="7.62" y="-1.27"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-7.62" y="-1.27"/>
</symbol>
<symbol name="WMCU_VDD">
<wire layer="94" width="0.25" x1="-2.54" y1="0" x2="2.54" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="+3V3" visible="pad" length="short" direction="sup" rot="R90" x="0" y="-2.54"/>
</symbol>
<symbol name="WMCU_VDD_23_0">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="RES_0402">
<wire layer="94" width="0.25" x1="3.175" y1="-1.27" x2="3.81" y2="0"/>
<wire layer="94" width="0.25" x1="1.905" y1="1.27" x2="3.175" y2="-1.27"/>
<wire layer="94" width="0.25" x1="0.635" y1="-1.27" x2="1.905" y2="1.27"/>
<wire layer="94" width="0.25" x1="-0.635" y1="1.27" x2="0.635" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.905" y1="-1.27" x2="-0.635" y2="1.27"/>
<wire layer="94" width="0.25" x1="-3.175" y1="1.27" x2="-1.905" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-3.81" y1="0" x2="-3.175" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<text x="0" y="-2.112" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="top-center" distance="50">>VALUE</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="6.35" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-6.35" y="0"/>
</symbol>
<symbol name="RES_0402_25_0">
<wire layer="94" width="0.25" x1="3.175" y1="-1.27" x2="3.81" y2="0"/>
<wire layer="94" width="0.25" x1="1.905" y1="1.27" x2="3.175" y2="-1.27"/>
<wire layer="94" width="0.25" x1="0.635" y1="-1.27" x2="1.905" y2="1.27"/>
<wire layer="94" width="0.25" x1="-0.635" y1="1.27" x2="0.635" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.905" y1="-1.27" x2="-0.635" y2="1.27"/>
<wire layer="94" width="0.25" x1="-3.175" y1="1.27" x2="-1.905" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-3.81" y1="0" x2="-3.175" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="6.35" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-6.35" y="0"/>
</symbol>
<symbol name="RES_0402_26_0">
<wire layer="94" width="0.25" x1="3.175" y1="-1.27" x2="3.81" y2="0"/>
<wire layer="94" width="0.25" x1="1.905" y1="1.27" x2="3.175" y2="-1.27"/>
<wire layer="94" width="0.25" x1="0.635" y1="-1.27" x2="1.905" y2="1.27"/>
<wire layer="94" width="0.25" x1="-0.635" y1="1.27" x2="0.635" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.905" y1="-1.27" x2="-0.635" y2="1.27"/>
<wire layer="94" width="0.25" x1="-3.175" y1="1.27" x2="-1.905" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-3.81" y1="0" x2="-3.175" y2="1.27"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="6.35" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-6.35" y="0"/>
</symbol>
<symbol name="SINGLECONNECT">
<wire layer="94" width="0.25" x1="-2.54" y1="2.54" x2="3.81" y2="2.54"/>
<wire layer="94" width="0.25" x1="3.81" y1="2.54" x2="3.81" y2="-2.54"/>
<wire layer="94" width="0.25" x1="3.81" y1="-2.54" x2="-2.54" y2="-2.54"/>
<wire layer="94" width="0.25" x1="-2.54" y1="-2.54" x2="-2.54" y2="2.54"/>
<text x="0.635" y="3.123" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-5.08" y="0"/>
</symbol>
<symbol name="CC2640(LONG_PADS)">
<wire layer="94" width="0.25" x1="0" y1="0" x2="58.42" y2="0"/>
<wire layer="94" width="0.25" x1="58.42" y1="0" x2="58.42" y2="46.99"/>
<wire layer="94" width="0.25" x1="58.42" y1="46.99" x2="0" y2="46.99"/>
<wire layer="94" width="0.25" x1="0" y1="46.99" x2="0" y2="0"/>
<text x="58.42" y="47.573" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-left" distance="50">>NAME</text>
<pin name="RF_P" visible="both" length="short" direction="nc" x="-2.54" y="38.1"/>
<pin name="RF_N" visible="both" length="short" direction="nc" x="-2.54" y="35.56"/>
<pin name="X32K_Q1" visible="both" length="short" direction="nc" x="-2.54" y="33.02"/>
<pin name="X32K_Q2" visible="both" length="short" direction="nc" x="-2.54" y="30.48"/>
<pin name="DIO_0" visible="both" length="short" direction="nc" x="-2.54" y="27.94"/>
<pin name="DIO_1" visible="both" length="short" direction="nc" x="-2.54" y="25.4"/>
<pin name="DIO_2" visible="both" length="short" direction="nc" x="-2.54" y="22.86"/>
<pin name="DIO_3" visible="both" length="short" direction="nc" x="-2.54" y="20.32"/>
<pin name="DIO_4" visible="both" length="short" direction="nc" x="-2.54" y="17.78"/>
<pin name="DIO_5" visible="both" length="short" direction="nc" x="-2.54" y="15.24"/>
<pin name="DIO_6" visible="both" length="short" direction="nc" x="-2.54" y="12.7"/>
<pin name="DIO_7" visible="both" length="short" direction="nc" x="-2.54" y="10.16"/>
<pin name="VDDS2" visible="both" length="short" direction="nc" rot="R90" x="13.97" y="-2.54"/>
<pin name="DIO_8" visible="both" length="short" direction="nc" rot="R90" x="16.51" y="-2.54"/>
<pin name="DIO_9" visible="both" length="short" direction="nc" rot="R90" x="19.05" y="-2.54"/>
<pin name="DIO_10" visible="both" length="short" direction="nc" rot="R90" x="21.59" y="-2.54"/>
<pin name="DIO_11" visible="both" length="short" direction="nc" rot="R90" x="24.13" y="-2.54"/>
<pin name="DIO_12" visible="both" length="short" direction="nc" rot="R90" x="26.67" y="-2.54"/>
<pin name="DIO_13" visible="both" length="short" direction="nc" rot="R90" x="29.21" y="-2.54"/>
<pin name="DIO_14" visible="both" length="short" direction="nc" rot="R90" x="31.75" y="-2.54"/>
<pin name="DIO_15" visible="both" length="short" direction="nc" rot="R90" x="34.29" y="-2.54"/>
<pin name="VDDS3" visible="both" length="short" direction="nc" rot="R90" x="36.83" y="-2.54"/>
<pin name="DCOUPL" visible="both" length="short" direction="nc" rot="R90" x="39.37" y="-2.54"/>
<pin name="JTAG_TMSC" visible="both" length="short" direction="nc" rot="R90" x="41.91" y="-2.54"/>
<pin name="JTAG_TCKC" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="10.16"/>
<pin name="DIO_16" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="12.7"/>
<pin name="DIO_17" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="15.24"/>
<pin name="DIO_18" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="17.78"/>
<pin name="DIO_19" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="20.32"/>
<pin name="DIO_20" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="22.86"/>
<pin name="DIO_21" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="25.4"/>
<pin name="DIO_22" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="27.94"/>
<pin name="DCDC_SW" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="30.48"/>
<pin name="VDDS_DCDC" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="33.02"/>
<pin name="RESET_N" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="35.56"/>
<pin name="DIO_23" visible="both" length="short" direction="nc" rot="R180" x="60.96" y="38.1"/>
<pin name="DIO_24" visible="both" length="short" direction="nc" rot="R270" x="41.91" y="49.53"/>
<pin name="DIO_25" visible="both" length="short" direction="nc" rot="R270" x="39.37" y="49.53"/>
<pin name="DIO_26" visible="both" length="short" direction="nc" rot="R270" x="36.83" y="49.53"/>
<pin name="DIO_27" visible="both" length="short" direction="nc" rot="R270" x="34.29" y="49.53"/>
<pin name="DIO_28" visible="both" length="short" direction="nc" rot="R270" x="31.75" y="49.53"/>
<pin name="DIO_29" visible="both" length="short" direction="nc" rot="R270" x="29.21" y="49.53"/>
<pin name="DIO_30" visible="both" length="short" direction="nc" rot="R270" x="26.67" y="49.53"/>
<pin name="VDDS" visible="both" length="short" direction="nc" rot="R270" x="24.13" y="49.53"/>
<pin name="VDDR" visible="both" length="short" direction="nc" rot="R270" x="21.59" y="49.53"/>
<pin name="X24M_N" visible="both" length="short" direction="nc" rot="R270" x="19.05" y="49.53"/>
<pin name="X24M_P" visible="both" length="short" direction="nc" rot="R270" x="16.51" y="49.53"/>
<pin name="VDDR_RF" visible="both" length="short" direction="nc" rot="R270" x="13.97" y="49.53"/>
<pin name="GND" visible="pad" length="short" direction="nc" x="-2.54" y="0"/>
</symbol>
<symbol name="SINGLE_PROBE_POINT">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="BLM18HE152SN1">
<wire layer="94" width="0.254" x1="0.944" y1="1.911" x2="0.944" y2="-1.911" curve="74.02156"/>
<wire layer="94" width="0.25" x1="-0.33" y1="-1.905" x2="-0.33" y2="1.905"/>
<wire layer="94" width="0.25" x1="0.305" y1="0" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="-0.33" y2="0"/>
<text x="0" y="2.494" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<text x="-8.438" y="-2.522" size="1.619" layer="94" font="vector" ratio="10" rot="R0" align="top-left" distance="76">BLM18HE152SN1</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="3.81" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-3.81" y="0"/>
</symbol>
<symbol name="VDDS">
<wire layer="94" width="0.25" x1="-2.54" y1="0" x2="2.54" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="+3V" visible="pad" length="short" direction="sup" rot="R90" x="0" y="-2.54"/>
</symbol>
<symbol name="VDDR">
<wire layer="94" width="0.25" x1="-2.54" y1="0" x2="2.54" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="VCC" visible="pad" length="short" direction="sup" rot="R90" x="0" y="-2.54"/>
</symbol>
<symbol name="SW3">
<circle layer="94" x="-0.476" y="0" radius="0.794" width="0.25"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0.317" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="TSX-3225">
<wire layer="94" width="0.25" x1="6.35" y1="11.43" x2="8.89" y2="11.43"/>
<wire layer="94" width="0.25" x1="8.89" y1="11.43" x2="8.89" y2="6.35"/>
<wire layer="94" width="0.25" x1="8.89" y1="6.35" x2="6.35" y2="6.35"/>
<wire layer="94" width="0.25" x1="6.35" y1="6.35" x2="6.35" y2="11.43"/>
<wire layer="94" width="0.25" x1="10.16" y1="11.43" x2="10.16" y2="6.35"/>
<wire layer="94" width="0.25" x1="5.08" y1="11.43" x2="5.08" y2="6.35"/>
<wire layer="94" width="0.25" x1="3.81" y1="11.43" x2="3.81" y2="13.97"/>
<wire layer="94" width="0.25" x1="3.81" y1="13.97" x2="11.43" y2="13.97"/>
<wire layer="94" width="0.25" x1="3.81" y1="5.08" x2="3.81" y2="3.81"/>
<wire layer="94" width="0.25" x1="3.81" y1="5.08" x2="11.43" y2="5.08"/>
<wire layer="94" width="0.25" x1="11.43" y1="3.81" x2="11.43" y2="5.08"/>
<wire layer="94" width="0.25" x1="11.43" y1="13.97" x2="11.43" y2="11.43"/>
<text x="7.62" y="14.553" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="2.54" y="8.89"/>
<pin name="3" visible="pad" length="short" direction="nc" rot="R180" x="12.7" y="8.89"/>
<pin name="2" visible="pad" length="short" direction="nc" rot="R90" x="3.81" y="1.27"/>
<pin name="4" visible="pad" length="short" direction="nc" rot="R90" x="11.43" y="1.27"/>
</symbol>
<symbol name="SW2">
<circle layer="94" x="-0.476" y="0" radius="0.794" width="0.25"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0.317" y2="0"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="SW2_36_0">
<circle layer="94" x="-0.476" y="0" radius="0.794" width="0.25"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0.317" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="SCL">
<wire layer="94" width="0.25" x1="2.54" y1="0" x2="1.27" y2="-1.27"/>
<wire layer="94" width="0.25" x1="1.27" y1="-1.27" x2="-1.27" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="-2.54" y2="0"/>
<wire layer="94" width="0.25" x1="-2.54" y1="0" x2="-1.27" y2="1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="1.27" x2="1.27" y2="1.27"/>
<wire layer="94" width="0.25" x1="1.27" y1="1.27" x2="2.54" y2="0"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="5.08" y="0"/>
</symbol>
<symbol name="SCL_38_0">
<wire layer="94" width="0.25" x1="2.54" y1="0" x2="1.27" y2="-1.27"/>
<wire layer="94" width="0.25" x1="1.27" y1="-1.27" x2="-1.27" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="-2.54" y2="0"/>
<wire layer="94" width="0.25" x1="-2.54" y1="0" x2="-1.27" y2="1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="1.27" x2="1.27" y2="1.27"/>
<wire layer="94" width="0.25" x1="1.27" y1="1.27" x2="2.54" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="5.08" y="0"/>
</symbol>
<symbol name="SW0">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="5050660622">
<wire layer="94" width="0.25" x1="-6.35" y1="7.62" x2="6.35" y2="7.62"/>
<wire layer="94" width="0.25" x1="6.35" y1="7.62" x2="6.35" y2="-7.62"/>
<wire layer="94" width="0.25" x1="6.35" y1="-7.62" x2="-6.35" y2="-7.62"/>
<wire layer="94" width="0.25" x1="-6.35" y1="-7.62" x2="-6.35" y2="7.62"/>
<wire layer="94" width="0.25" x1="-5.08" y1="6.35" x2="5.08" y2="6.35"/>
<wire layer="94" width="0.25" x1="5.08" y1="6.35" x2="5.08" y2="-6.35"/>
<wire layer="94" width="0.25" x1="5.08" y1="-6.35" x2="-5.08" y2="-6.35"/>
<wire layer="94" width="0.25" x1="-5.08" y1="-6.35" x2="-5.08" y2="6.35"/>
<text x="-6.933" y="0" size="1.619" layer="95" font="vector" ratio="10" rot="R90" align="bottom-center" distance="50">>NAME</text>
<pin name="VCC" visible="both" length="short" direction="nc" rot="R90" x="-2.54" y="-8.89"/>
<pin name="SDA" visible="both" length="short" direction="nc" rot="R90" x="0" y="-8.89"/>
<pin name="N/C@1" visible="both" length="short" direction="nc" rot="R90" x="2.54" y="-8.89"/>
<pin name="GND" visible="both" length="short" direction="nc" rot="R270" x="-2.54" y="8.89"/>
<pin name="SCL" visible="both" length="short" direction="nc" rot="R270" x="0" y="8.89"/>
<pin name="N/C@2" visible="both" length="short" direction="nc" rot="R270" x="2.54" y="8.89"/>
</symbol>
<symbol name="BT_ANTENNA">
<polygon layer="94" width="0.002">
<vertex x="-5" y="6"/>
<vertex x="5" y="6"/>
<vertex x="0" y="12"/>
<vertex x="0" y="12"/>
</polygon>
<wire layer="94" width="0.25" x1="0" y1="11.43" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="8.89" y2="0"/>
<wire layer="94" width="0.25" x1="-2.54" y1="11.43" x2="-2.54" y2="11.43"/>
<wire layer="94" width="0.25" x1="5.08" y1="12.7" x2="5.08" y2="12.7"/>
<text x="1.905" y="18.363" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" rot="R180" x="7.62" y="0"/>
</symbol>
<symbol name="TDO">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="TDO_43_0">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="TDI">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="TDI_45_0">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
<symbol name="WMCU_RXD">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="WMCU_RXD_47_0">
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="0"/>
<wire layer="94" width="0.25" x1="0" y1="0" x2="-1.27" y2="1.27"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" x="-2.54" y="0"/>
</symbol>
<symbol name="WMCU_RXD_48_0">
<circle layer="94" x="0" y="0" radius="1.27" width="0.25"/>
<text x="0" y="-2.083" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="1" visible="pad" length="short" direction="nc" x="-3.81" y="0"/>
</symbol>
</symbols>
<devicesets>
<deviceset name="WMCU_TCK" prefix="NetPort">
<gates>
<gate name="1" symbol="WMCU_TCK" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_TXD" prefix="NetPort">
<gates>
<gate name="1" symbol="WMCU_TXD" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_TXD_2" prefix="NetPort">
<gates>
<gate name="1" symbol="WMCU_TXD_2_0" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_TXD_3" prefix="WMCU_TXD">
<gates>
<gate name="1" symbol="WMCU_TXD_3_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="DCDC_SW" prefix="NetPort">
<gates>
<gate name="1" symbol="DCDC_SW" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_TMS" prefix="NetPort">
<gates>
<gate name="1" symbol="WMCU_TMS" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_TMS_6" prefix="WMCU_TMS">
<gates>
<gate name="1" symbol="WMCU_TMS_6_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SW1" prefix="NetPort">
<gates>
<gate name="1" symbol="SW1" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SW1_8" prefix="NetPort">
<gates>
<gate name="1" symbol="SW1_8_0" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="FC-135" prefix="Y">
<gates>
<gate name="1" symbol="FC-135" x="-6.35" y="-2.54"/>
</gates>
<devices>
<device name="" package="FC-135">
<connects>
<connect gate="1" pin="1" pad="1"/>
<connect gate="1" pin="2" pad="2"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="32.768kHz"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="GND" prefix="GND">
<gates>
<gate name="1" symbol="GND" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="GND_11" prefix="NetPort">
<gates>
<gate name="1" symbol="GND_11_0" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SDA" prefix="NetPort">
<gates>
<gate name="1" symbol="SDA" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SDA_13" prefix="NetPort">
<gates>
<gate name="1" symbol="SDA_13_0" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SWO" prefix="NetPort">
<gates>
<gate name="1" symbol="SWO" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="CAP_0603" prefix="C">
<gates>
<gate name="1" symbol="CAP_0603" x="0" y="0"/>
</gates>
<devices>
<device name="" package="CAP_0603">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="10uF"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="IND_0805" prefix="L">
<gates>
<gate name="1" symbol="IND_0805" x="0" y="0"/>
</gates>
<devices>
<device name="" package="IND_0805">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="10uH"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_RESET" prefix="NetPort">
<gates>
<gate name="1" symbol="WMCU_RESET" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_RESET_18" prefix="WMCU_RESET">
<gates>
<gate name="1" symbol="WMCU_RESET_18_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="CAP_0402" prefix="C">
<gates>
<gate name="1" symbol="CAP_0402" x="0" y="0"/>
</gates>
<devices>
<device name="" package="CAP_0402">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="100nF"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="CAP_0402_20" prefix="C">
<gates>
<gate name="1" symbol="CAP_0402_20_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="CAP_0402">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="1pF"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="IND_0402" prefix="L">
<gates>
<gate name="1" symbol="IND_0402" x="0" y="0"/>
</gates>
<devices>
<device name="" package="IND_0402">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="2.4nH"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_VDD" prefix="NetPort">
<gates>
<gate name="1" symbol="WMCU_VDD" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_VDD_23" prefix="WMCU_VDD">
<gates>
<gate name="1" symbol="WMCU_VDD_23_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="RES_0402" prefix="R">
<gates>
<gate name="1" symbol="RES_0402" x="0" y="0"/>
</gates>
<devices>
<device name="" package="RES_0402">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="100k"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="RES_0402_25" prefix="R">
<gates>
<gate name="1" symbol="RES_0402_25_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="RES_0402">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="3.3k"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="RES_0402_26" prefix="R">
<gates>
<gate name="1" symbol="RES_0402_26_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="RES_0402">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="100"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SINGLECONNECT" prefix="Switch">
<gates>
<gate name="1" symbol="SINGLECONNECT" x="-0.635" y="0"/>
</gates>
<devices>
<device name="" package="SINGLECONNECT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="CC2640(LONG_PADS)" prefix="U">
<gates>
<gate name="1" symbol="CC2640(LONG_PADS)" x="-29.21" y="-23.495"/>
</gates>
<devices>
<device name="" package="RGZ0048A-VQFN-48(LONGER_PADS)">
<connects>
<connect gate="1" pin="RF_P" pad="1"/>
<connect gate="1" pin="RF_N" pad="2"/>
<connect gate="1" pin="X32K_Q1" pad="3"/>
<connect gate="1" pin="X32K_Q2" pad="4"/>
<connect gate="1" pin="DIO_0" pad="5"/>
<connect gate="1" pin="DIO_1" pad="6"/>
<connect gate="1" pin="DIO_2" pad="7"/>
<connect gate="1" pin="DIO_3" pad="8"/>
<connect gate="1" pin="DIO_4" pad="9"/>
<connect gate="1" pin="DIO_5" pad="10"/>
<connect gate="1" pin="DIO_6" pad="11"/>
<connect gate="1" pin="DIO_7" pad="12"/>
<connect gate="1" pin="VDDS2" pad="13"/>
<connect gate="1" pin="DIO_8" pad="14"/>
<connect gate="1" pin="DIO_9" pad="15"/>
<connect gate="1" pin="DIO_10" pad="16"/>
<connect gate="1" pin="DIO_11" pad="17"/>
<connect gate="1" pin="DIO_12" pad="18"/>
<connect gate="1" pin="DIO_13" pad="19"/>
<connect gate="1" pin="DIO_14" pad="20"/>
<connect gate="1" pin="DIO_15" pad="21"/>
<connect gate="1" pin="VDDS3" pad="22"/>
<connect gate="1" pin="DCOUPL" pad="23"/>
<connect gate="1" pin="JTAG_TMSC" pad="24"/>
<connect gate="1" pin="JTAG_TCKC" pad="25"/>
<connect gate="1" pin="DIO_16" pad="26"/>
<connect gate="1" pin="DIO_17" pad="27"/>
<connect gate="1" pin="DIO_18" pad="28"/>
<connect gate="1" pin="DIO_19" pad="29"/>
<connect gate="1" pin="DIO_20" pad="30"/>
<connect gate="1" pin="DIO_21" pad="31"/>
<connect gate="1" pin="DIO_22" pad="32"/>
<connect gate="1" pin="DCDC_SW" pad="33"/>
<connect gate="1" pin="VDDS_DCDC" pad="34"/>
<connect gate="1" pin="RESET_N" pad="35"/>
<connect gate="1" pin="DIO_23" pad="36"/>
<connect gate="1" pin="DIO_24" pad="37"/>
<connect gate="1" pin="DIO_25" pad="38"/>
<connect gate="1" pin="DIO_26" pad="39"/>
<connect gate="1" pin="DIO_27" pad="40"/>
<connect gate="1" pin="DIO_28" pad="41"/>
<connect gate="1" pin="DIO_29" pad="42"/>
<connect gate="1" pin="DIO_30" pad="43"/>
<connect gate="1" pin="VDDS" pad="44"/>
<connect gate="1" pin="VDDR" pad="45"/>
<connect gate="1" pin="X24M_N" pad="46"/>
<connect gate="1" pin="X24M_P" pad="47"/>
<connect gate="1" pin="VDDR_RF" pad="48"/>
<connect gate="1" pin="GND" pad="49"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SINGLE_PROBE_POINT" prefix="WMCU_TCK">
<gates>
<gate name="1" symbol="SINGLE_PROBE_POINT" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="BLM18HE152SN1" prefix="FL">
<gates>
<gate name="1" symbol="BLM18HE152SN1" x="0" y="0"/>
</gates>
<devices>
<device name="" package="CAP_0603_31">
<connects>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="VDDS" prefix="NetPort">
<gates>
<gate name="1" symbol="VDDS" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="VDDR" prefix="NetPort">
<gates>
<gate name="1" symbol="VDDR" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SW3" prefix="NetPort">
<gates>
<gate name="1" symbol="SW3" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="TSX-3225" prefix="Y">
<gates>
<gate name="1" symbol="TSX-3225" x="-7.62" y="-8.89"/>
</gates>
<devices>
<device name="" package="TSX-3225">
<connects>
<connect gate="1" pin="1" pad="1"/>
<connect gate="1" pin="3" pad="3"/>
<connect gate="1" pin="2" pad="2"/>
<connect gate="1" pin="4" pad="4"/>
</connects>
<technologies>
<technology name="">
<attribute name="VALUE" value="24MHz"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SW2" prefix="NetPort">
<gates>
<gate name="1" symbol="SW2" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SW2_36" prefix="NetPort">
<gates>
<gate name="1" symbol="SW2_36_0" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SCL" prefix="SCL">
<gates>
<gate name="1" symbol="SCL" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SCL_38" prefix="SCL">
<gates>
<gate name="1" symbol="SCL_38_0" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="SW0" prefix="SW">
<gates>
<gate name="1" symbol="SW0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="5050660622" prefix="U">
<gates>
<gate name="1" symbol="5050660622" x="0" y="0"/>
</gates>
<devices>
<device name="" package="5050660622">
<connects>
<connect gate="1" pin="VCC" pad="4"/>
<connect gate="1" pin="SDA" pad="5"/>
<connect gate="1" pin="N/C@1" pad="6"/>
<connect gate="1" pin="GND" pad="1"/>
<connect gate="1" pin="SCL" pad="2"/>
<connect gate="1" pin="N/C@2" pad="3"/>
</connects>
<technologies>
<technology name="">
<attribute name="MANUFACTURER" value="Molex"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="BT_ANTENNA" prefix="A">
<gates>
<gate name="1" symbol="BT_ANTENNA" x="-1.905" y="-8.89"/>
</gates>
<devices>
<device name="" package="BT_ANTENNA">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="TDO" prefix="NetPort">
<gates>
<gate name="1" symbol="TDO" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="TDO_43" prefix="TDO">
<gates>
<gate name="1" symbol="TDO_43_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="TDI" prefix="NetPort">
<gates>
<gate name="1" symbol="TDI" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="TDI_45" prefix="TDI">
<gates>
<gate name="1" symbol="TDI_45_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_RXD" prefix="NetPort">
<gates>
<gate name="1" symbol="WMCU_RXD" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_RXD_47" prefix="NetPort">
<gates>
<gate name="1" symbol="WMCU_RXD_47_0" x="0" y="0"/>
</gates>
<devices>
<device name="">
<connects/>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="WMCU_RXD_48" prefix="WMCU_RXD">
<gates>
<gate name="1" symbol="WMCU_RXD_48_0" x="0" y="0"/>
</gates>
<devices>
<device name="" package="SINGLE_PROBE_POINT">
<connects>
<connect gate="1" pin="1" pad="1"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
</devicesets>
</library>
</libraries>
<classes>
<class number="0" name="Default" width="0" drill="0"/>
</classes>
<parts>
<part name="A1" library="common" deviceset="BT_ANTENNA" device=""/>
<part name="C3" library="common" deviceset="CAP_0402" device="" value="100nF"/>
<part name="C4" library="common" deviceset="CAP_0402" device="" value="100nF"/>
<part name="C5" library="common" deviceset="CAP_0402" device="" value="100nF"/>
<part name="C6" library="common" deviceset="CAP_0603" device="" value="10uF"/>
<part name="C7" library="common" deviceset="CAP_0402" device="" value="100nF"/>
<part name="C8" library="common" deviceset="CAP_0603" device="" value="10uF"/>
<part name="C9" library="common" deviceset="CAP_0402" device="" value="100nF"/>
<part name="C11" library="common" deviceset="CAP_0402_20" device="" value="1pF"/>
<part name="C13" library="common" deviceset="CAP_0402_20" device="" value="1pF"/>
<part name="C16" library="common" deviceset="CAP_0402" device="" value="100nF"/>
<part name="C17" library="common" deviceset="CAP_0402_20" device="" value="12pF"/>
<part name="C18" library="common" deviceset="CAP_0402_20" device="" value="12pF"/>
<part name="C19" library="common" deviceset="CAP_0402_20" device="" value="1uF"/>
<part name="C20" library="common" deviceset="CAP_0402" device="" value="100nF"/>
<part name="C21" library="common" deviceset="CAP_0402_20" device="" value="1pF"/>
<part name="C24" library="common" deviceset="CAP_0402_20" device="" value="12pF"/>
<part name="C31" library="common" deviceset="CAP_0402_20" device="" value="6.8pF"/>
<part name="C51" library="common" deviceset="CAP_0402_20" device="" value="1.8pF"/>
<part name="FL1" library="common" deviceset="BLM18HE152SN1" device=""/>
<part name="GND" library="common" deviceset="GND" device=""/>
<part name="L1" library="common" deviceset="IND_0805" device="" value="10uH"/>
<part name="L11" library="common" deviceset="IND_0402" device="" value="2.4nH"/>
<part name="L12" library="common" deviceset="IND_0402" device="" value="2nH"/>
<part name="L13" library="common" deviceset="IND_0402" device="" value="2nH"/>
<part name="L21" library="common" deviceset="IND_0402" device="" value="2.4nH"/>
<part name="NetPort1" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort2" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort3" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort4" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort5" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort6" library="common" deviceset="WMCU_VDD" device="" value="WMCU_VDD"/>
<part name="NetPort7" library="common" deviceset="VDDS" device="" value="VDDS"/>
<part name="NetPort8" library="common" deviceset="VDDS" device="" value="VDDS"/>
<part name="NetPort9" library="common" deviceset="VDDS" device="" value="VDDS"/>
<part name="NetPort10" library="common" deviceset="VDDS" device="" value="VDDS"/>
<part name="NetPort11" library="common" deviceset="VDDS" device="" value="VDDS"/>
<part name="NetPort12" library="common" deviceset="DCDC_SW" device="" value="DCDC_SW"/>
<part name="NetPort13" library="common" deviceset="VDDR" device="" value="VDDR"/>
<part name="NetPort14" library="common" deviceset="VDDR" device="" value="VDDR"/>
<part name="NetPort15" library="common" deviceset="VDDR" device="" value="VDDR"/>
<part name="NetPort16" library="common" deviceset="WMCU_TCK" device="" value="WMCU_TCK"/>
<part name="NetPort17" library="common" deviceset="WMCU_TMS" device="" value="WMCU_TMS"/>
<part name="NetPort18" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort19" library="common" deviceset="VDDS" device="" value="VDDS"/>
<part name="NetPort20" library="common" deviceset="WMCU_RESET" device="" value="WMCU_RESET"/>
<part name="NetPort21" library="common" deviceset="DCDC_SW" device="" value="DCDC_SW"/>
<part name="NetPort22" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort23" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort24" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort25" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort26" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort27" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort28" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort29" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort30" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort31" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort34" library="common" deviceset="WMCU_RXD" device="" value="WMCU_RXD"/>
<part name="NetPort35" library="common" deviceset="WMCU_TCK" device="" value="WMCU_TCK"/>
<part name="NetPort36" library="common" deviceset="WMCU_RXD_47" device="" value="WMCU_RXD"/>
<part name="NetPort37" library="common" deviceset="WMCU_TXD" device="" value="WMCU_TXD"/>
<part name="NetPort38" library="common" deviceset="WMCU_TXD_2" device="" value="WMCU_TXD"/>
<part name="NetPort39" library="common" deviceset="WMCU_RESET" device="" value="WMCU_RESET"/>
<part name="NetPort40" library="common" deviceset="WMCU_TMS" device="" value="WMCU_TMS"/>
<part name="NetPort41" library="common" deviceset="TDI" device="" value="TDI"/>
<part name="NetPort42" library="common" deviceset="TDO" device="" value="TDO"/>
<part name="NetPort43" library="common" deviceset="TDO" device="" value="TDO"/>
<part name="NetPort44" library="common" deviceset="TDI" device="" value="TDI"/>
<part name="NetPort45" library="common" deviceset="SWO" device="" value="SWO"/>
<part name="NetPort46" library="common" deviceset="SWO" device="" value="SWO"/>
<part name="NetPort47" library="common" deviceset="WMCU_VDD" device="" value="WMCU_VDD"/>
<part name="NetPort48" library="common" deviceset="WMCU_RESET" device="" value="WMCU_RESET"/>
<part name="NetPort49" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort50" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="NetPort51" library="common" deviceset="WMCU_VDD" device="" value="WMCU_VDD"/>
<part name="NetPort63" library="common" deviceset="SDA" device="" value="SDA"/>
<part name="NetPort64" library="common" deviceset="SDA_13" device="" value="SDA"/>
<part name="NetPort65" library="common" deviceset="WMCU_VDD" device="" value="WMCU_VDD"/>
<part name="NetPort67" library="common" deviceset="SW1" device="" value="SW1"/>
<part name="NetPort68" library="common" deviceset="SW2" device="" value="SW2"/>
<part name="NetPort69" library="common" deviceset="SW3" device="" value="SW3"/>
<part name="NetPort70" library="common" deviceset="SW1_8" device="" value="SW1"/>
<part name="NetPort71" library="common" deviceset="SW2_36" device="" value="SW2"/>
<part name="NetPort72" library="common" deviceset="SW3" device="" value="SW3"/>
<part name="NetPort73" library="common" deviceset="GND_11" device="" value="GND"/>
<part name="R1" library="common" deviceset="RES_0402" device="" value="100k"/>
<part name="R2" library="common" deviceset="RES_0402_25" device="" value="3.3k"/>
<part name="R3" library="common" deviceset="RES_0402_25" device="" value="3.3k"/>
<part name="R4" library="common" deviceset="RES_0402_26" device="" value="100"/>
<part name="R5" library="common" deviceset="RES_0402_26" device="" value="100"/>
<part name="R6" library="common" deviceset="RES_0402_26" device="" value="100"/>
<part name="RESET" library="common" deviceset="RES_0402_25" device="" value="N/A DO NOT CONNECT"/>
<part name="SCL" library="common" deviceset="SCL" device="" value="SCL"/>
<part name="SCL1" library="common" deviceset="SCL_38" device="" value="SCL"/>
<part name="SW0" library="common" deviceset="SW0" device=""/>
<part name="Switch1" library="common" deviceset="SINGLECONNECT" device=""/>
<part name="Switch2" library="common" deviceset="SINGLECONNECT" device=""/>
<part name="Switch3" library="common" deviceset="SINGLECONNECT" device=""/>
<part name="TDI" library="common" deviceset="TDI_45" device=""/>
<part name="TDO" library="common" deviceset="TDO_43" device=""/>
<part name="U1" library="common" deviceset="CC2640(LONG_PADS)" device=""/>
<part name="U3" library="common" deviceset="5050660622" device=""/>
<part name="WMCU_RESET" library="common" deviceset="WMCU_RESET_18" device=""/>
<part name="WMCU_RXD" library="common" deviceset="WMCU_RXD_48" device=""/>
<part name="WMCU_TCK" library="common" deviceset="SINGLE_PROBE_POINT" device=""/>
<part name="WMCU_TMS" library="common" deviceset="WMCU_TMS_6" device=""/>
<part name="WMCU_TXD" library="common" deviceset="WMCU_TXD_3" device=""/>
<part name="WMCU_VDD" library="common" deviceset="WMCU_VDD_23" device=""/>
<part name="Y1" library="common" deviceset="FC-135" device="" value="32.768kHz"/>
<part name="Y2" library="common" deviceset="TSX-3225" device="" value="24MHz"/>
</parts>
<modules/>
<sheets>
<sheet>
<description>Sheet1</description>
<plain>
<wire layer="97" width="0.333" x1="-302.8" y1="107.55" x2="-282.8" y2="107.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="107.55" x2="-282.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="102.55" x2="-302.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="102.55" x2="-302.8" y2="107.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="102.55" x2="-282.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="102.55" x2="-282.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="97.55" x2="-302.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="97.55" x2="-302.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="97.55" x2="-282.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="97.55" x2="-282.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="92.55" x2="-302.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="92.55" x2="-302.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="92.55" x2="-282.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="92.55" x2="-282.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="87.55" x2="-302.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="87.55" x2="-302.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="87.55" x2="-282.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="87.55" x2="-282.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="82.55" x2="-302.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="82.55" x2="-302.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="82.55" x2="-282.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="82.55" x2="-282.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="77.55" x2="-302.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="77.55" x2="-302.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="77.55" x2="-282.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="77.55" x2="-282.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="72.55" x2="-302.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="72.55" x2="-302.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="72.55" x2="-282.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="72.55" x2="-282.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="67.55" x2="-302.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="67.55" x2="-302.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="67.55" x2="-282.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="67.55" x2="-282.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="62.55" x2="-302.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="62.55" x2="-302.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="62.55" x2="-282.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="62.55" x2="-282.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="53.812" x2="-302.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="53.812" x2="-302.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-302.8" y1="53.812" x2="-282.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="53.812" x2="-282.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="48.812" x2="-302.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="48.812" x2="-302.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="48.812" x2="-282.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="48.812" x2="-282.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="43.812" x2="-302.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="43.812" x2="-302.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="43.812" x2="-282.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="43.812" x2="-282.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="38.812" x2="-302.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="38.812" x2="-302.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="38.812" x2="-282.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="38.812" x2="-282.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="33.812" x2="-302.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="33.812" x2="-302.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="33.812" x2="-282.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="33.812" x2="-282.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="28.812" x2="-302.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="28.812" x2="-302.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="28.812" x2="-282.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="28.812" x2="-282.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="23.812" x2="-302.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="23.812" x2="-302.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="23.812" x2="-282.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="23.812" x2="-282.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="18.812" x2="-302.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="18.812" x2="-302.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="18.812" x2="-282.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="18.812" x2="-282.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-282.8" y1="6.335" x2="-302.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-302.8" y1="6.335" x2="-302.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-302.8" y1="6.335" x2="-282.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-282.8" y1="6.335" x2="-282.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-282.8" y1="1.335" x2="-302.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-302.8" y1="1.335" x2="-302.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-302.8" y1="1.335" x2="-282.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-282.8" y1="1.335" x2="-282.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-7.403" x2="-302.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-7.403" x2="-302.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-7.403" x2="-282.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-7.403" x2="-282.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-12.403" x2="-302.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-12.403" x2="-302.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-12.403" x2="-282.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-12.403" x2="-282.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-17.403" x2="-302.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-17.403" x2="-302.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-17.403" x2="-282.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-17.403" x2="-282.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-26.141" x2="-302.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-26.141" x2="-302.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-26.141" x2="-282.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-26.141" x2="-282.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-31.141" x2="-302.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-31.141" x2="-302.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-31.141" x2="-282.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-31.141" x2="-282.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-39.88" x2="-302.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-39.88" x2="-302.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-39.88" x2="-282.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-39.88" x2="-282.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-44.88" x2="-302.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-44.88" x2="-302.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-44.88" x2="-282.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-44.88" x2="-282.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-53.618" x2="-302.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-53.618" x2="-302.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-53.618" x2="-282.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-53.618" x2="-282.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-58.618" x2="-302.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-58.618" x2="-302.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-58.618" x2="-282.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-58.618" x2="-282.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-63.618" x2="-302.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-63.618" x2="-302.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-63.618" x2="-282.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-63.618" x2="-282.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-68.618" x2="-302.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-68.618" x2="-302.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-68.618" x2="-282.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-68.618" x2="-282.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-73.618" x2="-302.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-73.618" x2="-302.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-73.618" x2="-282.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-73.618" x2="-282.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-78.618" x2="-302.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-78.618" x2="-302.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-78.618" x2="-282.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-78.618" x2="-282.8" y2="-83.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-83.618" x2="-302.8" y2="-83.618"/>
<wire layer="97" width="0.333" x1="-302.8" y1="-83.618" x2="-302.8" y2="-78.618"/>
<text x="-292.8" y="105.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center" distance="92">Name</text>
<text x="-301.8" y="100.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">BT_Antenna</text>
<text x="-301.8" y="95.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-301.8" y="90.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0603</text>
<text x="-301.8" y="85.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-301.8" y="80.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-301.8" y="75.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-301.8" y="70.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-301.8" y="65.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-301.8" y="58.181" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">BLM18HE152SN1</text>
<text x="-301.8" y="51.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">GND</text>
<text x="-301.8" y="46.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">IND_0805</text>
<text x="-301.8" y="41.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">IND_0402</text>
<text x="-301.8" y="36.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">IND_0402</text>
<text x="-301.8" y="31.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">RES_0402</text>
<text x="-301.8" y="26.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">RES_0402</text>
<text x="-301.8" y="21.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">RES_0402</text>
<text x="-301.8" y="12.573" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">RES_0402</text>
<text x="-301.8" y="3.835" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">SW0</text>
<text x="-301.8" y="-3.034" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">SingleConnect</text>
<text x="-301.8" y="-9.903" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">TDI</text>
<text x="-301.8" y="-14.903" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">TDO</text>
<text x="-301.8" y="-21.772" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CC2640(long
pads)</text>
<text x="-301.8" y="-28.641" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">5050660622</text>
<text x="-301.8" y="-35.511" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">WMCU_RESET</text>
<text x="-301.8" y="-42.38" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">WMCU_RXD</text>
<text x="-301.8" y="-49.249" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">single_probe
point</text>
<text x="-301.8" y="-56.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">WMCU_TMS</text>
<text x="-301.8" y="-61.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">WMCU_TXD</text>
<text x="-301.8" y="-66.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">WMCU_VDD</text>
<text x="-301.8" y="-71.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">FC-135</text>
<text x="-301.8" y="-76.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">TSX-3225</text>
<text x="-301.8" y="-81.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<wire layer="97" width="0.333" x1="-282.8" y1="107.55" x2="-262.8" y2="107.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="107.55" x2="-262.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="102.55" x2="-282.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="102.55" x2="-282.8" y2="107.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="102.55" x2="-262.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="102.55" x2="-262.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="97.55" x2="-282.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="97.55" x2="-282.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="97.55" x2="-262.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="97.55" x2="-262.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="92.55" x2="-282.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="92.55" x2="-282.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="92.55" x2="-262.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="92.55" x2="-262.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="87.55" x2="-282.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="87.55" x2="-282.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="87.55" x2="-262.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="87.55" x2="-262.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="82.55" x2="-282.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="82.55" x2="-282.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="82.55" x2="-262.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="82.55" x2="-262.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="77.55" x2="-282.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="77.55" x2="-282.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="77.55" x2="-262.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="77.55" x2="-262.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="72.55" x2="-282.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="72.55" x2="-282.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="72.55" x2="-262.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="72.55" x2="-262.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="67.55" x2="-282.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="67.55" x2="-282.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="67.55" x2="-262.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="67.55" x2="-262.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="62.55" x2="-282.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="62.55" x2="-282.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="62.55" x2="-262.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="62.55" x2="-262.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="53.812" x2="-282.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="53.812" x2="-282.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-282.8" y1="53.812" x2="-262.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="53.812" x2="-262.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="48.812" x2="-282.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="48.812" x2="-282.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="48.812" x2="-262.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="48.812" x2="-262.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="43.812" x2="-282.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="43.812" x2="-282.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="43.812" x2="-262.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="43.812" x2="-262.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="38.812" x2="-282.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="38.812" x2="-282.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="38.812" x2="-262.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="38.812" x2="-262.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="33.812" x2="-282.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="33.812" x2="-282.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="33.812" x2="-262.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="33.812" x2="-262.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="28.812" x2="-282.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="28.812" x2="-282.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="28.812" x2="-262.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="28.812" x2="-262.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="23.812" x2="-282.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="23.812" x2="-282.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="23.812" x2="-262.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="23.812" x2="-262.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="18.812" x2="-282.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="18.812" x2="-282.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="18.812" x2="-262.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="18.812" x2="-262.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-262.8" y1="6.335" x2="-282.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-282.8" y1="6.335" x2="-282.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-282.8" y1="6.335" x2="-262.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-262.8" y1="6.335" x2="-262.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-262.8" y1="1.335" x2="-282.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-282.8" y1="1.335" x2="-282.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-282.8" y1="1.335" x2="-262.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-262.8" y1="1.335" x2="-262.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-7.403" x2="-282.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-7.403" x2="-282.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-7.403" x2="-262.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-7.403" x2="-262.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-12.403" x2="-282.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-12.403" x2="-282.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-12.403" x2="-262.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-12.403" x2="-262.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-17.403" x2="-282.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-17.403" x2="-282.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-17.403" x2="-262.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-17.403" x2="-262.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-26.141" x2="-282.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-26.141" x2="-282.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-26.141" x2="-262.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-26.141" x2="-262.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-31.141" x2="-282.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-31.141" x2="-282.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-31.141" x2="-262.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-31.141" x2="-262.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-39.88" x2="-282.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-39.88" x2="-282.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-39.88" x2="-262.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-39.88" x2="-262.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-44.88" x2="-282.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-44.88" x2="-282.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-44.88" x2="-262.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-44.88" x2="-262.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-53.618" x2="-282.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-53.618" x2="-282.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-53.618" x2="-262.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-53.618" x2="-262.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-58.618" x2="-282.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-58.618" x2="-282.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-58.618" x2="-262.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-58.618" x2="-262.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-63.618" x2="-282.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-63.618" x2="-282.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-63.618" x2="-262.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-63.618" x2="-262.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-68.618" x2="-282.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-68.618" x2="-282.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-68.618" x2="-262.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-68.618" x2="-262.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-73.618" x2="-282.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-73.618" x2="-282.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-73.618" x2="-262.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-73.618" x2="-262.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-78.618" x2="-282.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-78.618" x2="-282.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-78.618" x2="-262.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-78.618" x2="-262.8" y2="-83.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-83.618" x2="-282.8" y2="-83.618"/>
<wire layer="97" width="0.333" x1="-282.8" y1="-83.618" x2="-282.8" y2="-78.618"/>
<text x="-272.8" y="105.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center" distance="92">Value</text>
<text x="-281.8" y="100.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="95.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">100nF</text>
<text x="-281.8" y="90.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">10uF</text>
<text x="-281.8" y="85.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1pF</text>
<text x="-281.8" y="80.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">12pF</text>
<text x="-281.8" y="75.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1uF</text>
<text x="-281.8" y="70.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">6.8pF</text>
<text x="-281.8" y="65.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1.8pF</text>
<text x="-281.8" y="58.181" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="51.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="46.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">10uH</text>
<text x="-281.8" y="41.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">2.4nH</text>
<text x="-281.8" y="36.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">2nH</text>
<text x="-281.8" y="31.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">100k</text>
<text x="-281.8" y="26.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">3.3k</text>
<text x="-281.8" y="21.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">100</text>
<text x="-281.8" y="12.573" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">N/A DO
NOT
CONNECT</text>
<text x="-281.8" y="3.835" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-3.034" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-9.903" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-14.903" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-21.772" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-28.641" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-35.511" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-42.38" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-49.249" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-56.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-61.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-66.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-281.8" y="-71.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">32.768kHz</text>
<text x="-281.8" y="-76.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">24MHz</text>
<text x="-281.8" y="-81.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<wire layer="97" width="0.333" x1="-262.8" y1="107.55" x2="-242.8" y2="107.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="107.55" x2="-242.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="102.55" x2="-262.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="102.55" x2="-262.8" y2="107.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="102.55" x2="-242.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="102.55" x2="-242.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="97.55" x2="-262.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="97.55" x2="-262.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="97.55" x2="-242.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="97.55" x2="-242.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="92.55" x2="-262.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="92.55" x2="-262.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="92.55" x2="-242.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="92.55" x2="-242.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="87.55" x2="-262.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="87.55" x2="-262.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="87.55" x2="-242.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="87.55" x2="-242.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="82.55" x2="-262.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="82.55" x2="-262.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="82.55" x2="-242.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="82.55" x2="-242.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="77.55" x2="-262.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="77.55" x2="-262.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="77.55" x2="-242.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="77.55" x2="-242.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="72.55" x2="-262.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="72.55" x2="-262.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="72.55" x2="-242.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="72.55" x2="-242.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="67.55" x2="-262.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="67.55" x2="-262.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="67.55" x2="-242.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="67.55" x2="-242.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="62.55" x2="-262.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="62.55" x2="-262.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="62.55" x2="-242.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="62.55" x2="-242.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="53.812" x2="-262.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="53.812" x2="-262.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-262.8" y1="53.812" x2="-242.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="53.812" x2="-242.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="48.812" x2="-262.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="48.812" x2="-262.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="48.812" x2="-242.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="48.812" x2="-242.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="43.812" x2="-262.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="43.812" x2="-262.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="43.812" x2="-242.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="43.812" x2="-242.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="38.812" x2="-262.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="38.812" x2="-262.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="38.812" x2="-242.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="38.812" x2="-242.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="33.812" x2="-262.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="33.812" x2="-262.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="33.812" x2="-242.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="33.812" x2="-242.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="28.812" x2="-262.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="28.812" x2="-262.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="28.812" x2="-242.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="28.812" x2="-242.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="23.812" x2="-262.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="23.812" x2="-262.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="23.812" x2="-242.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="23.812" x2="-242.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="18.812" x2="-262.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="18.812" x2="-262.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="18.812" x2="-242.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="18.812" x2="-242.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-242.8" y1="6.335" x2="-262.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-262.8" y1="6.335" x2="-262.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-262.8" y1="6.335" x2="-242.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-242.8" y1="6.335" x2="-242.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-242.8" y1="1.335" x2="-262.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-262.8" y1="1.335" x2="-262.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-262.8" y1="1.335" x2="-242.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-242.8" y1="1.335" x2="-242.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-7.403" x2="-262.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-7.403" x2="-262.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-7.403" x2="-242.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-7.403" x2="-242.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-12.403" x2="-262.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-12.403" x2="-262.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-12.403" x2="-242.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-12.403" x2="-242.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-17.403" x2="-262.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-17.403" x2="-262.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-17.403" x2="-242.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-17.403" x2="-242.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-26.141" x2="-262.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-26.141" x2="-262.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-26.141" x2="-242.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-26.141" x2="-242.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-31.141" x2="-262.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-31.141" x2="-262.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-31.141" x2="-242.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-31.141" x2="-242.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-39.88" x2="-262.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-39.88" x2="-262.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-39.88" x2="-242.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-39.88" x2="-242.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-44.88" x2="-262.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-44.88" x2="-262.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-44.88" x2="-242.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-44.88" x2="-242.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-53.618" x2="-262.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-53.618" x2="-262.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-53.618" x2="-242.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-53.618" x2="-242.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-58.618" x2="-262.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-58.618" x2="-262.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-58.618" x2="-242.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-58.618" x2="-242.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-63.618" x2="-262.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-63.618" x2="-262.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-63.618" x2="-242.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-63.618" x2="-242.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-68.618" x2="-262.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-68.618" x2="-262.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-68.618" x2="-242.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-68.618" x2="-242.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-73.618" x2="-262.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-73.618" x2="-262.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-73.618" x2="-242.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-73.618" x2="-242.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-78.618" x2="-262.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-78.618" x2="-262.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-78.618" x2="-242.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-78.618" x2="-242.8" y2="-83.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-83.618" x2="-262.8" y2="-83.618"/>
<wire layer="97" width="0.333" x1="-262.8" y1="-83.618" x2="-262.8" y2="-78.618"/>
<text x="-252.8" y="105.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center" distance="92">Manufacturer</text>
<text x="-261.8" y="100.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="95.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="90.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="85.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="80.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="75.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="70.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="65.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="58.181" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="51.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="46.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="41.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="36.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="31.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="26.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="21.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="12.573" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="3.835" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-3.034" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-9.903" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-14.903" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-21.772" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-28.641" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">Molex</text>
<text x="-261.8" y="-35.511" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-42.38" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-49.249" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-56.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-61.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-66.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-71.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-76.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-261.8" y="-81.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<wire layer="97" width="0.333" x1="-242.8" y1="107.55" x2="-222.8" y2="107.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="107.55" x2="-222.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="102.55" x2="-242.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="102.55" x2="-242.8" y2="107.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="102.55" x2="-222.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="102.55" x2="-222.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="97.55" x2="-242.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="97.55" x2="-242.8" y2="102.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="97.55" x2="-222.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="97.55" x2="-222.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="92.55" x2="-242.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="92.55" x2="-242.8" y2="97.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="92.55" x2="-222.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="92.55" x2="-222.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="87.55" x2="-242.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="87.55" x2="-242.8" y2="92.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="87.55" x2="-222.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="87.55" x2="-222.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="82.55" x2="-242.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="82.55" x2="-242.8" y2="87.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="82.55" x2="-222.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="82.55" x2="-222.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="77.55" x2="-242.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="77.55" x2="-242.8" y2="82.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="77.55" x2="-222.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="77.55" x2="-222.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="72.55" x2="-242.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="72.55" x2="-242.8" y2="77.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="72.55" x2="-222.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="72.55" x2="-222.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="67.55" x2="-242.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="67.55" x2="-242.8" y2="72.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="67.55" x2="-222.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="67.55" x2="-222.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="62.55" x2="-242.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="62.55" x2="-242.8" y2="67.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="62.55" x2="-222.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-222.8" y1="62.55" x2="-222.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="53.812" x2="-242.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="53.812" x2="-242.8" y2="62.55"/>
<wire layer="97" width="0.333" x1="-242.8" y1="53.812" x2="-222.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="53.812" x2="-222.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="48.812" x2="-242.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="48.812" x2="-242.8" y2="53.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="48.812" x2="-222.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="48.812" x2="-222.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="43.812" x2="-242.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="43.812" x2="-242.8" y2="48.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="43.812" x2="-222.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="43.812" x2="-222.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="38.812" x2="-242.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="38.812" x2="-242.8" y2="43.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="38.812" x2="-222.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="38.812" x2="-222.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="33.812" x2="-242.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="33.812" x2="-242.8" y2="38.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="33.812" x2="-222.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="33.812" x2="-222.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="28.812" x2="-242.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="28.812" x2="-242.8" y2="33.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="28.812" x2="-222.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="28.812" x2="-222.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="23.812" x2="-242.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="23.812" x2="-242.8" y2="28.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="23.812" x2="-222.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="23.812" x2="-222.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="18.812" x2="-242.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="18.812" x2="-242.8" y2="23.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="18.812" x2="-222.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-222.8" y1="18.812" x2="-222.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-222.8" y1="6.335" x2="-242.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-242.8" y1="6.335" x2="-242.8" y2="18.812"/>
<wire layer="97" width="0.333" x1="-242.8" y1="6.335" x2="-222.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-222.8" y1="6.335" x2="-222.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-222.8" y1="1.335" x2="-242.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-242.8" y1="1.335" x2="-242.8" y2="6.335"/>
<wire layer="97" width="0.333" x1="-242.8" y1="1.335" x2="-222.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-222.8" y1="1.335" x2="-222.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-7.403" x2="-242.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-7.403" x2="-242.8" y2="1.335"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-7.403" x2="-222.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-7.403" x2="-222.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-12.403" x2="-242.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-12.403" x2="-242.8" y2="-7.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-12.403" x2="-222.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-12.403" x2="-222.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-17.403" x2="-242.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-17.403" x2="-242.8" y2="-12.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-17.403" x2="-222.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-17.403" x2="-222.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-26.141" x2="-242.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-26.141" x2="-242.8" y2="-17.403"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-26.141" x2="-222.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-26.141" x2="-222.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-31.141" x2="-242.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-31.141" x2="-242.8" y2="-26.141"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-31.141" x2="-222.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-31.141" x2="-222.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-39.88" x2="-242.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-39.88" x2="-242.8" y2="-31.141"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-39.88" x2="-222.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-39.88" x2="-222.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-44.88" x2="-242.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-44.88" x2="-242.8" y2="-39.88"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-44.88" x2="-222.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-44.88" x2="-222.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-53.618" x2="-242.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-53.618" x2="-242.8" y2="-44.88"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-53.618" x2="-222.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-53.618" x2="-222.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-58.618" x2="-242.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-58.618" x2="-242.8" y2="-53.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-58.618" x2="-222.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-58.618" x2="-222.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-63.618" x2="-242.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-63.618" x2="-242.8" y2="-58.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-63.618" x2="-222.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-63.618" x2="-222.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-68.618" x2="-242.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-68.618" x2="-242.8" y2="-63.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-68.618" x2="-222.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-68.618" x2="-222.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-73.618" x2="-242.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-73.618" x2="-242.8" y2="-68.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-73.618" x2="-222.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-73.618" x2="-222.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-78.618" x2="-242.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-78.618" x2="-242.8" y2="-73.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-78.618" x2="-222.8" y2="-78.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-78.618" x2="-222.8" y2="-83.618"/>
<wire layer="97" width="0.333" x1="-222.8" y1="-83.618" x2="-242.8" y2="-83.618"/>
<wire layer="97" width="0.333" x1="-242.8" y1="-83.618" x2="-242.8" y2="-78.618"/>
<text x="-232.8" y="105.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center" distance="92">Quantity</text>
<text x="-241.8" y="100.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="95.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">7</text>
<text x="-241.8" y="90.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">2</text>
<text x="-241.8" y="85.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">3</text>
<text x="-241.8" y="80.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">3</text>
<text x="-241.8" y="75.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="70.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="65.05" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="58.181" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="51.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="46.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="41.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">2</text>
<text x="-241.8" y="36.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">2</text>
<text x="-241.8" y="31.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="26.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">2</text>
<text x="-241.8" y="21.312" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">3</text>
<text x="-241.8" y="12.573" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="3.835" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-3.034" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">3</text>
<text x="-241.8" y="-9.903" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-14.903" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-21.772" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-28.641" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-35.511" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-42.38" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-49.249" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-56.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-61.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-66.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-71.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-76.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-241.8" y="-81.118" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">49</text>
</plain>
<moduleinsts/>
<instances>
<instance part="A1" gate="1" x="-161.29" y="7.62"/>
<instance part="C3" gate="1" x="-81.28" y="77.47" rot="R90.0002104592258"/>
<instance part="C4" gate="1" x="-67.31" y="77.47" rot="R90.0002104592258"/>
<instance part="C5" gate="1" x="-53.34" y="77.47" rot="R90.0002104592258"/>
<instance part="C6" gate="1" x="-39.37" y="77.47" rot="R90.0002104592258"/>
<instance part="C7" gate="1" x="-25.4" y="77.47" rot="R90.0002104592258"/>
<instance part="C8" gate="1" x="33.02" y="82.55" rot="R90.0002104592258"/>
<instance part="C9" gate="1" x="44.45" y="82.55" rot="R90.0002104592258"/>
<instance part="C11" gate="1" x="-64.77" y="13.97"/>
<instance part="C13" gate="1" x="-105.41" y="-2.54" rot="R90.0002104592258"/>
<instance part="C16" gate="1" x="55.88" y="82.55" rot="R90.0002104592258"/>
<instance part="C17" gate="1" x="-41.91" y="-16.51" rot="R90.0002104592258"/>
<instance part="C18" gate="1" x="-26.67" y="-16.51" rot="R90.0002104592258"/>
<instance part="C19" gate="1" x="40.64" y="-54.61" rot="R90.0002104592258"/>
<instance part="C20" gate="1" x="101.6" y="6.35" rot="R90.0002104592258"/>
<instance part="C21" gate="1" x="-50.8" y="-5.08" rot="R90.0002104592258"/>
<instance part="C24" gate="1" x="-133.35" y="7.62"/>
<instance part="C31" gate="1" x="-50.8" y="40.64" rot="R90.0002104592258"/>
<instance part="C51" gate="1" x="-144.78" y="7.62"/>
<instance part="FL1" gate="1" x="-102.87" y="91.44"/>
<instance part="GND" gate="1" x="-158.93" y="-70.31" rot="R180.000420918452"/>
<instance part="L1" gate="1" x="7.62" y="92.71"/>
<instance part="L11" gate="1" x="-52.07" y="24.13" rot="R90.0002104592258"/>
<instance part="L12" gate="1" x="-92.71" y="8.89"/>
<instance part="L13" gate="1" x="-116.84" y="8.89"/>
<instance part="L21" gate="1" x="-64.77" y="2.54"/>
<instance part="NetPort1" gate="1" x="-81.28" y="65.024"/>
<instance part="NetPort2" gate="1" x="-67.31" y="65.024"/>
<instance part="NetPort3" gate="1" x="-53.34" y="65.024"/>
<instance part="NetPort4" gate="1" x="-39.37" y="65.024"/>
<instance part="NetPort5" gate="1" x="-25.4" y="65.024"/>
<instance part="NetPort6" gate="1" x="-109.22" y="99.06"/>
<instance part="NetPort7" gate="1" x="-93.98" y="99.06"/>
<instance part="NetPort8" gate="1" x="8.89" y="-45.72"/>
<instance part="NetPort9" gate="1" x="44.45" y="-67.31"/>
<instance part="NetPort10" gate="1" x="48.26" y="40.64"/>
<instance part="NetPort11" gate="1" x="80.01" y="8.89"/>
<instance part="NetPort12" gate="1" x="-5.08" y="101.6"/>
<instance part="NetPort13" gate="1" x="39.37" y="101.6"/>
<instance part="NetPort14" gate="1" x="40.64" y="40.64"/>
<instance part="NetPort15" gate="1" x="-5.08" y="27.94"/>
<instance part="NetPort16" gate="1" x="109.22" y="-20.32"/>
<instance part="NetPort17" gate="1" x="62.23" y="-43.18"/>
<instance part="NetPort18" gate="1" x="101.6" y="-6.096"/>
<instance part="NetPort19" gate="1" x="101.6" y="39.37"/>
<instance part="NetPort20" gate="1" x="113.03" y="16.51"/>
<instance part="NetPort21" gate="1" x="88.9" y="3.81"/>
<instance part="NetPort22" gate="1" x="-34.29" y="-28.956"/>
<instance part="NetPort23" gate="1" x="63.5" y="-65.786"/>
<instance part="NetPort24" gate="1" x="-50.8" y="-13.716"/>
<instance part="NetPort25" gate="1" x="19.05" y="43.434"/>
<instance part="NetPort26" gate="1" x="-39.37" y="40.894"/>
<instance part="NetPort27" gate="1" x="-105.41" y="-13.716"/>
<instance part="NetPort28" gate="1" x="33.02" y="71.374"/>
<instance part="NetPort29" gate="1" x="44.45" y="71.374"/>
<instance part="NetPort30" gate="1" x="55.88" y="71.374"/>
<instance part="NetPort31" gate="1" x="-142.42" y="-79.096"/>
<instance part="NetPort34" gate="1" x="-12.7" y="-7.62" rot="R180.000420918452"/>
<instance part="NetPort35" gate="1" x="-125.91" y="-31.09"/>
<instance part="NetPort36" gate="1" x="-86.53" y="-57.76"/>
<instance part="NetPort37" gate="1" x="-16.51" y="-13.97" rot="R270.000631377677"/>
<instance part="NetPort38" gate="1" x="-93.48" y="-51.26"/>
<instance part="NetPort39" gate="1" x="-104.53" y="-45.06"/>
<instance part="NetPort40" gate="1" x="-116.33" y="-37.26"/>
<instance part="NetPort41" gate="1" x="95.25" y="-15.24"/>
<instance part="NetPort42" gate="1" x="100.33" y="-17.78"/>
<instance part="NetPort43" gate="1" x="-141.15" y="-18.39"/>
<instance part="NetPort44" gate="1" x="-134.8" y="-24.74"/>
<instance part="NetPort45" gate="1" x="88.9" y="-12.7"/>
<instance part="NetPort46" gate="1" x="-142.42" y="-12.04"/>
<instance part="NetPort47" gate="1" x="-67.64" y="-42.9"/>
<instance part="NetPort48" gate="1" x="-32.64" y="-75.25"/>
<instance part="NetPort49" gate="1" x="-133.35" y="51.054"/>
<instance part="NetPort50" gate="1" x="-68.2" y="-85.156"/>
<instance part="NetPort51" gate="1" x="-134.62" y="39.37"/>
<instance part="NetPort63" gate="1" x="-106.68" y="33.02" rot="R180.000420918452"/>
<instance part="NetPort64" gate="1" x="-11.43" y="-26.67"/>
<instance part="NetPort65" gate="1" x="-27.94" y="-53.34"/>
<instance part="NetPort67" gate="1" x="60.96" y="29.21" rot="R180.000420918452"/>
<instance part="NetPort68" gate="1" x="67.31" y="25.4" rot="R180.000420918452"/>
<instance part="NetPort69" gate="1" x="35.56" y="-69.85" rot="R90.0002104592258"/>
<instance part="NetPort70" gate="1" x="99.06" y="-44.45"/>
<instance part="NetPort71" gate="1" x="104.14" y="-53.34"/>
<instance part="NetPort72" gate="1" x="107.95" y="-62.23"/>
<instance part="NetPort73" gate="1" x="-2.54" y="-70.866"/>
<instance part="R1" gate="1" x="101.6" y="24.13" rot="R90.0002104592258"/>
<instance part="R2" gate="1" x="-13.97" y="-45.72" rot="R90.0002104592258"/>
<instance part="R3" gate="1" x="-6.35" y="-45.72" rot="R90.0002104592258"/>
<instance part="R4" gate="1" x="113.03" y="-44.45" rot="R180.000420918452"/>
<instance part="R5" gate="1" x="116.84" y="-53.34" rot="R180.000420918452"/>
<instance part="R6" gate="1" x="120.65" y="-62.23" rot="R180.000420918452"/>
<instance part="RESET" gate="1" x="-56.77" y="-75.25"/>
<instance part="SCL" gate="1" x="-100.33" y="58.42" rot="R180.000420918452"/>
<instance part="SCL1" gate="1" x="-20.32" y="-30.48"/>
<instance part="SW0" gate="1" x="-158.93" y="-11.96" rot="R180.000420918452"/>
<instance part="Switch1" gate="1" x="127" y="-44.45"/>
<instance part="Switch2" gate="1" x="130.81" y="-53.34"/>
<instance part="Switch3" gate="1" x="134.62" y="-62.23"/>
<instance part="TDI" gate="1" x="-158.93" y="-24.81" rot="R180.000420918452"/>
<instance part="TDO" gate="1" x="-158.93" y="-18.35" rot="R180.000420918452"/>
<instance part="U1" gate="1" x="1.27" y="-30.48"/>
<instance part="U3" gate="1" x="-118.11" y="45.72"/>
<instance part="WMCU_RESET" gate="1" x="-158.93" y="-45.01" rot="R180.000420918452"/>
<instance part="WMCU_RXD" gate="1" x="-158.93" y="-57.76" rot="R180.000420918452"/>
<instance part="WMCU_TCK" gate="1" x="-158.93" y="-31.19" rot="R180.000420918452"/>
<instance part="WMCU_TMS" gate="1" x="-158.93" y="-37.41" rot="R180.000420918452"/>
<instance part="WMCU_TXD" gate="1" x="-158.93" y="-51.36" rot="R180.000420918452"/>
<instance part="WMCU_VDD" gate="1" x="-158.93" y="-64.11" rot="R180.000420918452"/>
<instance part="Y1" gate="1" x="-41.275" y="-8.89"/>
<instance part="Y2" gate="1" x="12.065" y="48.26"/>
</instances>
<busses/>
<nets>
<net name="Net_0" class="0">
<segment>
<wire layer="91" width="0.1" x1="-81.28" y1="68.58" x2="-81.28" y2="73.66"/>
<pinref part="NetPort1" gate="1" pin="GND"/>
<pinref part="C3" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-67.31" y1="73.66" x2="-67.31" y2="68.58"/>
<pinref part="C4" gate="1" pin="1"/>
<pinref part="NetPort2" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-53.34" y1="73.66" x2="-53.34" y2="68.58"/>
<pinref part="C5" gate="1" pin="1"/>
<pinref part="NetPort3" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-39.37" y1="73.66" x2="-39.37" y2="68.58"/>
<pinref part="C6" gate="1" pin="1"/>
<pinref part="NetPort4" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-25.4" y1="73.66" x2="-25.4" y2="68.58"/>
<pinref part="C7" gate="1" pin="1"/>
<pinref part="NetPort5" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="101.6" y1="-2.54" x2="101.6" y2="2.54"/>
<pinref part="NetPort18" gate="1" pin="GND"/>
<pinref part="C20" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-41.91" y1="-21.59" x2="-41.91" y2="-20.32"/>
<wire layer="91" width="0.1" x1="-41.91" y1="-21.59" x2="-34.29" y2="-21.59"/>
<wire layer="91" width="0.1" x1="-34.29" y1="-21.59" x2="-34.29" y2="-25.4"/>
<pinref part="C17" gate="1" pin="1"/>
<pinref part="NetPort22" gate="1" pin="GND"/>
<wire layer="91" width="0.1" x1="-26.67" y1="-21.59" x2="-26.67" y2="-20.32"/>
<wire layer="91" width="0.1" x1="-26.67" y1="-21.59" x2="-34.29" y2="-21.59"/>
<pinref part="C18" gate="1" pin="1"/>
<junction x="-34.29" y="-21.59"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="63.5" y1="-60.96" x2="63.5" y2="-62.23"/>
<wire layer="91" width="0.1" x1="63.5" y1="-60.96" x2="40.64" y2="-60.96"/>
<wire layer="91" width="0.1" x1="40.64" y1="-60.96" x2="40.64" y2="-58.42"/>
<pinref part="NetPort23" gate="1" pin="GND"/>
<pinref part="C19" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="19.05" y1="48.26" x2="19.05" y2="46.99"/>
<wire layer="91" width="0.1" x1="23.495" y1="48.26" x2="23.495" y2="49.53"/>
<wire layer="91" width="0.1" x1="19.05" y1="48.26" x2="23.495" y2="48.26"/>
<pinref part="NetPort25" gate="1" pin="GND"/>
<pinref part="Y2" gate="1" pin="4"/>
<wire layer="91" width="0.1" x1="15.875" y1="48.26" x2="15.875" y2="49.53"/>
<wire layer="91" width="0.1" x1="15.875" y1="48.26" x2="19.05" y2="48.26"/>
<pinref part="Y2" gate="1" pin="2"/>
<junction x="19.05" y="48.26"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-50.8" y1="-8.89" x2="-50.8" y2="-10.16"/>
<pinref part="C21" gate="1" pin="1"/>
<pinref part="NetPort24" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-50.8" y1="44.45" x2="-50.8" y2="48.26"/>
<wire layer="91" width="0.1" x1="-50.8" y1="48.26" x2="-39.37" y2="48.26"/>
<wire layer="91" width="0.1" x1="-39.37" y1="48.26" x2="-39.37" y2="44.45"/>
<pinref part="C31" gate="1" pin="2"/>
<pinref part="NetPort26" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-105.41" y1="-6.35" x2="-105.41" y2="-10.16"/>
<pinref part="C13" gate="1" pin="1"/>
<pinref part="NetPort27" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="33.02" y1="78.74" x2="33.02" y2="74.93"/>
<pinref part="C8" gate="1" pin="1"/>
<pinref part="NetPort28" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="44.45" y1="74.93" x2="44.45" y2="78.74"/>
<pinref part="NetPort29" gate="1" pin="GND"/>
<pinref part="C9" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="55.88" y1="74.93" x2="55.88" y2="78.74"/>
<pinref part="NetPort30" gate="1" pin="GND"/>
<pinref part="C16" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-2.54" y1="-30.48" x2="-1.27" y2="-30.48"/>
<wire layer="91" width="0.1" x1="-2.54" y1="-30.48" x2="-2.54" y2="-67.31"/>
<pinref part="U1" gate="1" pin="GND"/>
<pinref part="NetPort73" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-133.35" y1="54.61" x2="-133.35" y2="58.42"/>
<wire layer="91" width="0.1" x1="-133.35" y1="58.42" x2="-120.65" y2="58.42"/>
<wire layer="91" width="0.1" x1="-120.65" y1="58.42" x2="-120.65" y2="54.61"/>
<pinref part="NetPort49" gate="1" pin="GND"/>
<pinref part="U3" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-68.2" y1="-81.6" x2="-68.2" y2="-75.25"/>
<wire layer="91" width="0.1" x1="-68.2" y1="-75.25" x2="-63.12" y2="-75.25"/>
<pinref part="NetPort50" gate="1" pin="GND"/>
<pinref part="RESET" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-142.42" y1="-75.54" x2="-142.42" y2="-70.31"/>
<wire layer="91" width="0.1" x1="-142.42" y1="-70.31" x2="-155.12" y2="-70.31"/>
<pinref part="NetPort31" gate="1" pin="GND"/>
<pinref part="GND" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_1" class="0">
<segment>
<wire layer="91" width="0.1" x1="-109.22" y1="96.52" x2="-109.22" y2="91.44"/>
<wire layer="91" width="0.1" x1="-109.22" y1="91.44" x2="-106.68" y2="91.44"/>
<pinref part="NetPort6" gate="1" pin="+3V3"/>
<pinref part="FL1" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-27.94" y1="-55.88" x2="-27.94" y2="-59.69"/>
<wire layer="91" width="0.1" x1="-27.94" y1="-59.69" x2="-13.97" y2="-59.69"/>
<wire layer="91" width="0.1" x1="-13.97" y1="-59.69" x2="-13.97" y2="-52.07"/>
<pinref part="NetPort65" gate="1" pin="+3V3"/>
<pinref part="R2" gate="1" pin="1"/>
<wire layer="91" width="0.1" x1="-6.35" y1="-52.07" x2="-6.35" y2="-59.69"/>
<wire layer="91" width="0.1" x1="-6.35" y1="-59.69" x2="-13.97" y2="-59.69"/>
<pinref part="R3" gate="1" pin="1"/>
<junction x="-13.97" y="-59.69"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-134.62" y1="36.83" x2="-134.62" y2="33.02"/>
<wire layer="91" width="0.1" x1="-134.62" y1="33.02" x2="-120.65" y2="33.02"/>
<wire layer="91" width="0.1" x1="-120.65" y1="33.02" x2="-120.65" y2="36.83"/>
<pinref part="NetPort51" gate="1" pin="+3V3"/>
<pinref part="U3" gate="1" pin="VCC"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-67.64" y1="-45.44" x2="-67.64" y2="-64.11"/>
<wire layer="91" width="0.1" x1="-67.64" y1="-64.11" x2="-155.12" y2="-64.11"/>
<pinref part="NetPort47" gate="1" pin="+3V3"/>
<pinref part="WMCU_VDD" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_2" class="0">
<segment>
<wire layer="91" width="0.1" x1="-39.37" y1="91.44" x2="-25.4" y2="91.44"/>
<wire layer="91" width="0.1" x1="-53.34" y1="91.44" x2="-39.37" y2="91.44"/>
<wire layer="91" width="0.1" x1="-67.31" y1="91.44" x2="-53.34" y2="91.44"/>
<wire layer="91" width="0.1" x1="-81.28" y1="91.44" x2="-67.31" y2="91.44"/>
<wire layer="91" width="0.1" x1="-99.06" y1="91.44" x2="-93.98" y2="91.44"/>
<wire layer="91" width="0.1" x1="-93.98" y1="91.44" x2="-81.28" y2="91.44"/>
<wire layer="91" width="0.1" x1="-25.4" y1="91.44" x2="-25.4" y2="81.28"/>
<pinref part="FL1" gate="1" pin="2"/>
<pinref part="C7" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="-81.28" y1="81.28" x2="-81.28" y2="91.44"/>
<pinref part="C3" gate="1" pin="2"/>
<junction x="-81.28" y="91.44"/>
<wire layer="91" width="0.1" x1="-67.31" y1="81.28" x2="-67.31" y2="91.44"/>
<pinref part="C4" gate="1" pin="2"/>
<junction x="-67.31" y="91.44"/>
<wire layer="91" width="0.1" x1="-53.34" y1="81.28" x2="-53.34" y2="91.44"/>
<pinref part="C5" gate="1" pin="2"/>
<junction x="-53.34" y="91.44"/>
<wire layer="91" width="0.1" x1="-39.37" y1="81.28" x2="-39.37" y2="91.44"/>
<pinref part="C6" gate="1" pin="2"/>
<junction x="-39.37" y="91.44"/>
<wire layer="91" width="0.1" x1="-93.98" y1="96.52" x2="-93.98" y2="91.44"/>
<pinref part="NetPort7" gate="1" pin="+3V"/>
<junction x="-93.98" y="91.44"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="15.24" y1="-33.02" x2="15.24" y2="-49.53"/>
<wire layer="91" width="0.1" x1="8.89" y1="-49.53" x2="8.89" y2="-48.26"/>
<wire layer="91" width="0.1" x1="15.24" y1="-49.53" x2="8.89" y2="-49.53"/>
<pinref part="U1" gate="1" pin="VDDS2"/>
<pinref part="NetPort8" gate="1" pin="+3V"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="44.45" y1="-71.12" x2="44.45" y2="-69.85"/>
<wire layer="91" width="0.1" x1="44.45" y1="-71.12" x2="38.1" y2="-71.12"/>
<wire layer="91" width="0.1" x1="38.1" y1="-71.12" x2="38.1" y2="-33.02"/>
<pinref part="NetPort9" gate="1" pin="+3V"/>
<pinref part="U1" gate="1" pin="VDDS3"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="25.4" y1="19.05" x2="25.4" y2="33.02"/>
<wire layer="91" width="0.1" x1="25.4" y1="33.02" x2="48.26" y2="33.02"/>
<wire layer="91" width="0.1" x1="48.26" y1="33.02" x2="48.26" y2="38.1"/>
<pinref part="U1" gate="1" pin="VDDS"/>
<pinref part="NetPort10" gate="1" pin="+3V"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="62.23" y1="2.54" x2="80.01" y2="2.54"/>
<wire layer="91" width="0.1" x1="80.01" y1="2.54" x2="80.01" y2="6.35"/>
<pinref part="U1" gate="1" pin="VDDS_DCDC"/>
<pinref part="NetPort11" gate="1" pin="+3V"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="101.6" y1="36.83" x2="101.6" y2="30.48"/>
<pinref part="NetPort19" gate="1" pin="+3V"/>
<pinref part="R1" gate="1" pin="2"/>
</segment>
</net>
<net name="Net_3" class="0">
<segment>
<wire layer="91" width="0.1" x1="-5.08" y1="99.06" x2="-5.08" y2="91.44"/>
<wire layer="91" width="0.1" x1="-5.08" y1="91.44" x2="0" y2="91.44"/>
<pinref part="NetPort12" gate="1" pin="VCC"/>
<pinref part="L1" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="88.9" y1="0" x2="88.9" y2="1.27"/>
<wire layer="91" width="0.1" x1="88.9" y1="0" x2="62.23" y2="0"/>
<pinref part="NetPort21" gate="1" pin="VCC"/>
<pinref part="U1" gate="1" pin="DCDC_SW"/>
</segment>
</net>
<net name="Net_4" class="0">
<segment>
<wire layer="91" width="0.1" x1="15.24" y1="91.44" x2="33.02" y2="91.44"/>
<wire layer="91" width="0.1" x1="33.02" y1="91.44" x2="33.02" y2="86.36"/>
<pinref part="L1" gate="1" pin="2"/>
<pinref part="C8" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="44.45" y1="86.36" x2="44.45" y2="91.44"/>
<wire layer="91" width="0.1" x1="44.45" y1="91.44" x2="39.37" y2="91.44"/>
<wire layer="91" width="0.1" x1="39.37" y1="91.44" x2="44.45" y2="91.44"/>
<wire layer="91" width="0.1" x1="44.45" y1="91.44" x2="33.02" y2="91.44"/>
<pinref part="C9" gate="1" pin="2"/>
<junction x="33.02" y="91.44"/>
<wire layer="91" width="0.1" x1="55.88" y1="86.36" x2="55.88" y2="91.44"/>
<wire layer="91" width="0.1" x1="55.88" y1="91.44" x2="44.45" y2="91.44"/>
<pinref part="C16" gate="1" pin="2"/>
<junction x="44.45" y="91.44"/>
<wire layer="91" width="0.1" x1="39.37" y1="99.06" x2="39.37" y2="91.44"/>
<pinref part="NetPort13" gate="1" pin="VCC"/>
<junction x="39.37" y="91.44"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="40.64" y1="38.1" x2="40.64" y2="35.56"/>
<wire layer="91" width="0.1" x1="40.64" y1="35.56" x2="22.86" y2="35.56"/>
<wire layer="91" width="0.1" x1="22.86" y1="35.56" x2="22.86" y2="19.05"/>
<pinref part="NetPort14" gate="1" pin="VCC"/>
<pinref part="U1" gate="1" pin="VDDR"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-5.08" y1="25.4" x2="-5.08" y2="20.32"/>
<wire layer="91" width="0.1" x1="15.24" y1="20.32" x2="15.24" y2="19.05"/>
<wire layer="91" width="0.1" x1="-5.08" y1="20.32" x2="15.24" y2="20.32"/>
<pinref part="NetPort15" gate="1" pin="VCC"/>
<pinref part="U1" gate="1" pin="VDDR_RF"/>
</segment>
</net>
<net name="Net_5" class="0">
<segment>
<wire layer="91" width="0.1" x1="62.23" y1="-20.32" x2="106.68" y2="-20.32"/>
<pinref part="U1" gate="1" pin="JTAG_TCKC"/>
<pinref part="NetPort16" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-129.72" y1="-31.19" x2="-128.45" y2="-31.09"/>
<wire layer="91" width="0.1" x1="-129.72" y1="-31.19" x2="-155.12" y2="-31.19"/>
<pinref part="NetPort35" gate="1" pin="1"/>
<pinref part="WMCU_TCK" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_6" class="0">
<segment>
<wire layer="91" width="0.1" x1="43.18" y1="-33.02" x2="43.18" y2="-43.18"/>
<wire layer="91" width="0.1" x1="43.18" y1="-43.18" x2="59.69" y2="-43.18"/>
<pinref part="U1" gate="1" pin="JTAG_TMSC"/>
<pinref part="NetPort17" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-120.14" y1="-37.41" x2="-118.87" y2="-37.26"/>
<wire layer="91" width="0.1" x1="-120.14" y1="-37.41" x2="-155.12" y2="-37.41"/>
<pinref part="NetPort40" gate="1" pin="1"/>
<pinref part="WMCU_TMS" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_7" class="0">
<segment>
<wire layer="91" width="0.1" x1="101.6" y1="17.78" x2="101.6" y2="15.24"/>
<wire layer="91" width="0.1" x1="101.6" y1="15.24" x2="101.6" y2="16.51"/>
<wire layer="91" width="0.1" x1="101.6" y1="16.51" x2="101.6" y2="10.16"/>
<pinref part="R1" gate="1" pin="1"/>
<pinref part="C20" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="62.23" y1="5.08" x2="74.93" y2="5.08"/>
<wire layer="91" width="0.1" x1="74.93" y1="5.08" x2="74.93" y2="15.24"/>
<wire layer="91" width="0.1" x1="74.93" y1="15.24" x2="101.6" y2="15.24"/>
<pinref part="U1" gate="1" pin="RESET_N"/>
<junction x="101.6" y="15.24"/>
<wire layer="91" width="0.1" x1="110.49" y1="16.51" x2="101.6" y2="16.51"/>
<pinref part="NetPort20" gate="1" pin="1"/>
<junction x="101.6" y="16.51"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-50.42" y1="-75.25" x2="-35.18" y2="-75.25"/>
<pinref part="RESET" gate="1" pin="2"/>
<pinref part="NetPort48" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-108.34" y1="-45.01" x2="-107.07" y2="-45.06"/>
<wire layer="91" width="0.1" x1="-108.34" y1="-45.01" x2="-155.12" y2="-45.01"/>
<pinref part="NetPort39" gate="1" pin="1"/>
<pinref part="WMCU_RESET" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_8" class="0">
<segment>
<wire layer="91" width="0.1" x1="-1.27" y1="2.54" x2="-41.91" y2="2.54"/>
<wire layer="91" width="0.1" x1="-41.91" y1="2.54" x2="-41.91" y2="-6.35"/>
<wire layer="91" width="0.1" x1="-41.91" y1="-6.35" x2="-40.005" y2="-6.35"/>
<pinref part="U1" gate="1" pin="X32K_Q1"/>
<pinref part="Y1" gate="1" pin="1"/>
<wire layer="91" width="0.1" x1="-41.91" y1="-12.7" x2="-41.91" y2="-6.35"/>
<pinref part="C17" gate="1" pin="2"/>
<junction x="-41.91" y="-6.35"/>
</segment>
</net>
<net name="Net_9" class="0">
<segment>
<wire layer="91" width="0.1" x1="-1.27" y1="0" x2="-26.67" y2="0"/>
<wire layer="91" width="0.1" x1="-26.67" y1="0" x2="-26.67" y2="-6.35"/>
<wire layer="91" width="0.1" x1="-26.67" y1="-6.35" x2="-29.845" y2="-6.35"/>
<pinref part="U1" gate="1" pin="X32K_Q2"/>
<pinref part="Y1" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="-26.67" y1="-12.7" x2="-26.67" y2="-6.35"/>
<pinref part="C18" gate="1" pin="2"/>
<junction x="-26.67" y="-6.35"/>
</segment>
</net>
<net name="Net_10" class="0">
<segment>
<wire layer="91" width="0.1" x1="40.64" y1="-33.02" x2="40.64" y2="-50.8"/>
<pinref part="U1" gate="1" pin="DCOUPL"/>
<pinref part="C19" gate="1" pin="2"/>
</segment>
</net>
<net name="Net_11" class="0">
<segment>
<wire layer="91" width="0.1" x1="14.605" y1="57.15" x2="10.16" y2="57.15"/>
<wire layer="91" width="0.1" x1="10.16" y1="57.15" x2="10.16" y2="38.1"/>
<wire layer="91" width="0.1" x1="10.16" y1="38.1" x2="17.78" y2="38.1"/>
<wire layer="91" width="0.1" x1="17.78" y1="38.1" x2="17.78" y2="19.05"/>
<pinref part="Y2" gate="1" pin="1"/>
<pinref part="U1" gate="1" pin="X24M_P"/>
</segment>
</net>
<net name="Net_12" class="0">
<segment>
<wire layer="91" width="0.1" x1="20.32" y1="19.05" x2="20.32" y2="38.1"/>
<wire layer="91" width="0.1" x1="20.32" y1="38.1" x2="27.94" y2="38.1"/>
<wire layer="91" width="0.1" x1="27.94" y1="38.1" x2="27.94" y2="57.15"/>
<wire layer="91" width="0.1" x1="27.94" y1="57.15" x2="24.765" y2="57.15"/>
<pinref part="U1" gate="1" pin="X24M_N"/>
<pinref part="Y2" gate="1" pin="3"/>
</segment>
</net>
<net name="Net_13" class="0">
<segment>
<wire layer="91" width="0.1" x1="-1.27" y1="5.08" x2="-45.72" y2="5.08"/>
<wire layer="91" width="0.1" x1="-45.72" y1="5.08" x2="-45.72" y2="1.27"/>
<wire layer="91" width="0.1" x1="-45.72" y1="1.27" x2="-50.8" y2="1.27"/>
<wire layer="91" width="0.1" x1="-50.8" y1="1.27" x2="-50.8" y2="-1.27"/>
<pinref part="U1" gate="1" pin="RF_N"/>
<pinref part="C21" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="-57.15" y1="1.27" x2="-50.8" y2="1.27"/>
<pinref part="L21" gate="1" pin="2"/>
<junction x="-50.8" y="1.27"/>
</segment>
</net>
<net name="Net_14" class="0">
<segment>
<wire layer="91" width="0.1" x1="-50.8" y1="13.97" x2="-45.72" y2="13.97"/>
<wire layer="91" width="0.1" x1="-60.96" y1="13.97" x2="-50.8" y2="13.97"/>
<wire layer="91" width="0.1" x1="-45.72" y1="13.97" x2="-45.72" y2="7.62"/>
<wire layer="91" width="0.1" x1="-45.72" y1="7.62" x2="-1.27" y2="7.62"/>
<pinref part="C11" gate="1" pin="2"/>
<pinref part="U1" gate="1" pin="RF_P"/>
<wire layer="91" width="0.1" x1="-50.8" y1="16.51" x2="-50.8" y2="13.97"/>
<pinref part="L11" gate="1" pin="1"/>
<junction x="-50.8" y="13.97"/>
</segment>
</net>
<net name="Net_15" class="0">
<segment>
<wire layer="91" width="0.1" x1="-50.8" y1="31.75" x2="-50.8" y2="36.83"/>
<pinref part="L11" gate="1" pin="2"/>
<pinref part="C31" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_16" class="0">
<segment>
<wire layer="91" width="0.1" x1="-72.39" y1="1.27" x2="-76.2" y2="1.27"/>
<wire layer="91" width="0.1" x1="-76.2" y1="7.62" x2="-76.2" y2="13.97"/>
<wire layer="91" width="0.1" x1="-76.2" y1="1.27" x2="-76.2" y2="7.62"/>
<wire layer="91" width="0.1" x1="-76.2" y1="13.97" x2="-68.58" y2="13.97"/>
<pinref part="L21" gate="1" pin="1"/>
<pinref part="C11" gate="1" pin="1"/>
<wire layer="91" width="0.1" x1="-85.09" y1="7.62" x2="-76.2" y2="7.62"/>
<pinref part="L12" gate="1" pin="2"/>
<junction x="-76.2" y="7.62"/>
</segment>
</net>
<net name="Net_17" class="0">
<segment>
<wire layer="91" width="0.1" x1="-105.41" y1="7.62" x2="-109.22" y2="7.62"/>
<wire layer="91" width="0.1" x1="-100.33" y1="7.62" x2="-105.41" y2="7.62"/>
<pinref part="L12" gate="1" pin="1"/>
<pinref part="L13" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="-105.41" y1="1.27" x2="-105.41" y2="7.62"/>
<pinref part="C13" gate="1" pin="2"/>
<junction x="-105.41" y="7.62"/>
</segment>
</net>
<net name="Net_18" class="0">
<segment>
<wire layer="91" width="0.1" x1="-124.46" y1="7.62" x2="-129.54" y2="7.62"/>
<pinref part="L13" gate="1" pin="1"/>
<pinref part="C24" gate="1" pin="2"/>
</segment>
</net>
<net name="Net_19" class="0">
<segment>
<wire layer="91" width="0.1" x1="-137.16" y1="7.62" x2="-140.97" y2="7.62"/>
<pinref part="C24" gate="1" pin="1"/>
<pinref part="C51" gate="1" pin="2"/>
</segment>
</net>
<net name="Net_20" class="0">
<segment>
<wire layer="91" width="0.1" x1="-153.67" y1="7.62" x2="-148.59" y2="7.62"/>
<pinref part="A1" gate="1" pin="1"/>
<pinref part="C51" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_21" class="0">
<segment>
<wire layer="91" width="0.1" x1="-1.27" y1="-7.62" x2="-10.16" y2="-7.62"/>
<pinref part="U1" gate="1" pin="DIO_2"/>
<pinref part="NetPort34" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-89.07" y1="-57.76" x2="-155.12" y2="-57.76"/>
<pinref part="NetPort36" gate="1" pin="1"/>
<pinref part="WMCU_RXD" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_22" class="0">
<segment>
<wire layer="91" width="0.1" x1="-16.51" y1="-10.16" x2="-16.51" y2="-11.43"/>
<wire layer="91" width="0.1" x1="-16.51" y1="-10.16" x2="-1.27" y2="-10.16"/>
<pinref part="NetPort37" gate="1" pin="1"/>
<pinref part="U1" gate="1" pin="DIO_3"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-97.29" y1="-51.36" x2="-96.02" y2="-51.26"/>
<wire layer="91" width="0.1" x1="-97.29" y1="-51.36" x2="-155.12" y2="-51.36"/>
<pinref part="NetPort38" gate="1" pin="1"/>
<pinref part="WMCU_TXD" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_23" class="0">
<segment>
<wire layer="91" width="0.1" x1="62.23" y1="-17.78" x2="97.79" y2="-17.78"/>
<pinref part="U1" gate="1" pin="DIO_16"/>
<pinref part="NetPort42" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-153.85" y1="-18.39" x2="-155.12" y2="-18.35"/>
<wire layer="91" width="0.1" x1="-153.85" y1="-18.39" x2="-143.69" y2="-18.39"/>
<pinref part="TDO" gate="1" pin="1"/>
<pinref part="NetPort43" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_24" class="0">
<segment>
<wire layer="91" width="0.1" x1="62.23" y1="-15.24" x2="92.71" y2="-15.24"/>
<pinref part="U1" gate="1" pin="DIO_17"/>
<pinref part="NetPort41" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-138.61" y1="-24.81" x2="-137.34" y2="-24.74"/>
<wire layer="91" width="0.1" x1="-138.61" y1="-24.81" x2="-155.12" y2="-24.81"/>
<pinref part="NetPort44" gate="1" pin="1"/>
<pinref part="TDI" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_25" class="0">
<segment>
<wire layer="91" width="0.1" x1="62.23" y1="-12.7" x2="86.36" y2="-12.7"/>
<pinref part="U1" gate="1" pin="DIO_18"/>
<pinref part="NetPort45" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-146.23" y1="-11.96" x2="-144.96" y2="-12.04"/>
<wire layer="91" width="0.1" x1="-146.23" y1="-11.96" x2="-155.12" y2="-11.96"/>
<pinref part="NetPort46" gate="1" pin="1"/>
<pinref part="SW0" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_30" class="0">
<segment>
<wire layer="91" width="0.1" x1="-6.35" y1="-26.67" x2="-7.62" y2="-26.67"/>
<wire layer="91" width="0.1" x1="-6.35" y1="-26.67" x2="-6.35" y2="-15.24"/>
<wire layer="91" width="0.1" x1="-6.35" y1="-15.24" x2="-1.27" y2="-15.24"/>
<pinref part="NetPort64" gate="1" pin="1"/>
<pinref part="U1" gate="1" pin="DIO_5"/>
<wire layer="91" width="0.1" x1="-6.35" y1="-39.37" x2="-6.35" y2="-26.67"/>
<pinref part="R3" gate="1" pin="2"/>
<junction x="-6.35" y="-26.67"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-118.11" y1="36.83" x2="-118.11" y2="33.02"/>
<wire layer="91" width="0.1" x1="-118.11" y1="33.02" x2="-110.49" y2="33.02"/>
<pinref part="U3" gate="1" pin="SDA"/>
<pinref part="NetPort63" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_31" class="0">
<segment>
<wire layer="91" width="0.1" x1="-1.27" y1="-12.7" x2="-13.97" y2="-12.7"/>
<wire layer="91" width="0.1" x1="-13.97" y1="-30.48" x2="-15.24" y2="-30.48"/>
<wire layer="91" width="0.1" x1="-13.97" y1="-12.7" x2="-13.97" y2="-30.48"/>
<pinref part="U1" gate="1" pin="DIO_4"/>
<pinref part="SCL1" gate="1" pin="1"/>
<wire layer="91" width="0.1" x1="-13.97" y1="-39.37" x2="-13.97" y2="-30.48"/>
<pinref part="R2" gate="1" pin="2"/>
<junction x="-13.97" y="-30.48"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-105.41" y1="58.42" x2="-118.11" y2="58.42"/>
<wire layer="91" width="0.1" x1="-118.11" y1="58.42" x2="-118.11" y2="54.61"/>
<pinref part="SCL" gate="1" pin="1"/>
<pinref part="U3" gate="1" pin="SCL"/>
</segment>
</net>
<net name="Net_32" class="0">
<segment>
<wire layer="91" width="0.1" x1="35.56" y1="-66.04" x2="35.56" y2="-33.02"/>
<pinref part="NetPort69" gate="1" pin="1"/>
<pinref part="U1" gate="1" pin="DIO_15"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="111.76" y1="-62.23" x2="114.3" y2="-62.23"/>
<pinref part="NetPort72" gate="1" pin="1"/>
<pinref part="R6" gate="1" pin="2"/>
</segment>
</net>
<net name="Net_33" class="0">
<segment>
<wire layer="91" width="0.1" x1="107.95" y1="-53.34" x2="110.49" y2="-53.34"/>
<pinref part="NetPort71" gate="1" pin="1"/>
<pinref part="R5" gate="1" pin="2"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="63.5" y1="25.4" x2="40.64" y2="25.4"/>
<wire layer="91" width="0.1" x1="40.64" y1="25.4" x2="40.64" y2="19.05"/>
<pinref part="NetPort68" gate="1" pin="1"/>
<pinref part="U1" gate="1" pin="DIO_25"/>
</segment>
</net>
<net name="Net_34" class="0">
<segment>
<wire layer="91" width="0.1" x1="102.87" y1="-44.45" x2="106.68" y2="-44.45"/>
<pinref part="NetPort70" gate="1" pin="1"/>
<pinref part="R4" gate="1" pin="2"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="57.15" y1="29.21" x2="38.1" y2="29.21"/>
<wire layer="91" width="0.1" x1="38.1" y1="29.21" x2="38.1" y2="19.05"/>
<pinref part="NetPort67" gate="1" pin="1"/>
<pinref part="U1" gate="1" pin="DIO_26"/>
</segment>
</net>
<net name="Net_35" class="0">
<segment>
<wire layer="91" width="0.1" x1="119.38" y1="-44.45" x2="121.92" y2="-44.45"/>
<pinref part="R4" gate="1" pin="1"/>
<pinref part="Switch1" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_36" class="0">
<segment>
<wire layer="91" width="0.1" x1="123.19" y1="-53.34" x2="125.73" y2="-53.34"/>
<pinref part="R5" gate="1" pin="1"/>
<pinref part="Switch2" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_37" class="0">
<segment>
<wire layer="91" width="0.1" x1="127" y1="-62.23" x2="129.54" y2="-62.23"/>
<pinref part="R6" gate="1" pin="1"/>
<pinref part="Switch3" gate="1" pin="1"/>
</segment>
</net>
</nets>
</sheet>
</sheets>
</schematic>
</drawing>
</eagle>
