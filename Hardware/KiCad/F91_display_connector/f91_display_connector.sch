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
<package name="DIO_0402">
<smd name="1" x="-0.65" y="0" layer="1" dx="0.7" dy="0.9" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.65" y="0" layer="1" dx="0.7" dy="0.9" rot="R90" stop="yes" cream="yes" thermals="no"/>
<wire layer="21" width="0.25" x1="-1.399" y1="-0.25" x2="-1.399" y2="0.25"/>
</package>
<package name="RES_0402">
<smd name="1" x="-0.65" y="0" layer="1" dx="0.7" dy="0.9" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.65" y="0" layer="1" dx="0.7" dy="0.9" rot="R90" stop="yes" cream="yes" thermals="no"/>
</package>
<package name="CAP_0402">
<description>Description: non polarized</description>
<smd name="1" x="-0.65" y="0" layer="1" dx="0.7" dy="0.9" rot="R90" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="0.65" y="0" layer="1" dx="0.7" dy="0.9" rot="R90" stop="yes" cream="yes" thermals="no"/>
</package>
<package name="5050700622">
<smd name="0@_1" x="-0.732" y="0.717" layer="1" dx="0.23" dy="0.535" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="0@_2" x="-0.732" y="-0.818" layer="1" dx="0.23" dy="0.535" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="3" x="-0.357" y="0.857" layer="1" dx="0.18" dy="0.485" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="-0.007" y="0.857" layer="1" dx="0.18" dy="0.485" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="1" x="0.343" y="0.857" layer="1" dx="0.18" dy="0.485" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="6" x="-0.357" y="-0.958" layer="1" dx="0.18" dy="0.485" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="5" x="-0.007" y="-0.958" layer="1" dx="0.18" dy="0.485" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="4" x="0.343" y="-0.958" layer="1" dx="0.18" dy="0.485" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="0@_3" x="0.718" y="0.717" layer="1" dx="0.23" dy="0.535" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="0@" x="0.718" y="-0.818" layer="1" dx="0.23" dy="0.535" rot="R0" stop="yes" cream="yes" thermals="no"/>
<wire layer="21" width="0.1" x1="-1.325" y1="1.179" x2="1.299" y2="1.179"/>
<wire layer="21" width="0.1" x1="1.299" y1="1.179" x2="1.299" y2="-1.271"/>
<wire layer="21" width="0.1" x1="1.299" y1="-1.271" x2="-1.325" y2="-1.271"/>
<wire layer="21" width="0.1" x1="-1.325" y1="-1.271" x2="-1.325" y2="1.179"/>
<dimension x1="-0.732" y1="0.449" x2="-0.732" y2="-0.551" x3="-2.535" y3="0.449" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-0.357" y1="0.857" x2="-0.007" y2="0.857" x3="-0.357" y3="2.626" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="-0.732" y1="0.984" x2="-0.357" y2="1.099" x3="-0.732" y3="5.132" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="0.343" y1="0.614" x2="0.343" y2="-0.716" x3="3.625" y3="0.614" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
<package name="0.83-OLED_28PIN">
<smd name="1" x="0.715" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="2" x="1.365" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="3" x="2.015" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="4" x="2.665" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="5" x="3.315" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="6" x="3.965" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="7" x="4.615" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="8" x="5.265" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="9" x="5.915" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="10" x="6.565" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="11" x="7.215" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="12" x="7.865" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="13" x="8.515" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="14" x="9.165" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="15" x="9.815" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="16" x="10.465" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="17" x="11.115" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="18" x="11.765" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="19" x="12.415" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="20" x="13.065" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="21" x="13.715" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="22" x="14.365" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="23" x="15.015" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="24" x="15.665" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="25" x="16.315" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="26" x="16.965" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="27" x="17.615" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<smd name="28" x="18.265" y="1.53" layer="1" dx="0.25" dy="2" rot="R0" stop="yes" cream="yes" thermals="no"/>
<wire layer="21" width="0.25" x1="0" y1="2.831" x2="18.84" y2="2.831"/>
<wire layer="21" width="0.25" x1="18.84" y1="2.831" x2="18.84" y2="0.05"/>
<wire layer="21" width="0.25" x1="18.84" y1="0.05" x2="0" y2="0.05"/>
<wire layer="21" width="0.25" x1="0" y1="0.05" x2="0" y2="2.831"/>
<wire layer="21" width="0.25" x1="1.086" y1="4.24" x2="0.985" y2="4.248"/>
<wire layer="21" width="0.25" x1="0.985" y1="4.248" x2="0.886" y2="4.272"/>
<wire layer="21" width="0.25" x1="0.886" y1="4.272" x2="0.793" y2="4.31"/>
<wire layer="21" width="0.25" x1="0.793" y1="4.31" x2="0.707" y2="4.363"/>
<wire layer="21" width="0.25" x1="0.707" y1="4.363" x2="0.63" y2="4.429"/>
<wire layer="21" width="0.25" x1="0.63" y1="4.429" x2="0.564" y2="4.506"/>
<wire layer="21" width="0.25" x1="0.564" y1="4.506" x2="0.511" y2="4.592"/>
<wire layer="21" width="0.25" x1="0.511" y1="4.592" x2="0.472" y2="4.686"/>
<wire layer="21" width="0.25" x1="0.472" y1="4.686" x2="0.449" y2="4.784"/>
<wire layer="21" width="0.25" x1="0.449" y1="4.784" x2="0.441" y2="4.885"/>
<wire layer="21" width="0.25" x1="0.441" y1="4.885" x2="0.449" y2="4.986"/>
<wire layer="21" width="0.25" x1="0.449" y1="4.986" x2="0.472" y2="5.084"/>
<wire layer="21" width="0.25" x1="0.472" y1="5.084" x2="0.511" y2="5.177"/>
<wire layer="21" width="0.25" x1="0.511" y1="5.177" x2="0.564" y2="5.264"/>
<wire layer="21" width="0.25" x1="0.564" y1="5.264" x2="0.63" y2="5.341"/>
<wire layer="21" width="0.25" x1="0.63" y1="5.341" x2="0.707" y2="5.406"/>
<wire layer="21" width="0.25" x1="0.707" y1="5.406" x2="0.793" y2="5.459"/>
<wire layer="21" width="0.25" x1="0.793" y1="5.459" x2="0.886" y2="5.498"/>
<wire layer="21" width="0.25" x1="0.886" y1="5.498" x2="0.985" y2="5.521"/>
<wire layer="21" width="0.25" x1="0.985" y1="5.521" x2="1.086" y2="5.529"/>
<wire layer="21" width="0.25" x1="1.086" y1="5.529" x2="1.145" y2="5.529"/>
<wire layer="21" width="0.25" x1="1.145" y1="5.529" x2="1.246" y2="5.521"/>
<wire layer="21" width="0.25" x1="1.246" y1="5.521" x2="1.344" y2="5.498"/>
<wire layer="21" width="0.25" x1="1.344" y1="5.498" x2="1.438" y2="5.459"/>
<wire layer="21" width="0.25" x1="1.438" y1="5.459" x2="1.524" y2="5.406"/>
<wire layer="21" width="0.25" x1="1.524" y1="5.406" x2="1.601" y2="5.341"/>
<wire layer="21" width="0.25" x1="1.601" y1="5.341" x2="1.667" y2="5.264"/>
<wire layer="21" width="0.25" x1="1.667" y1="5.264" x2="1.72" y2="5.177"/>
<wire layer="21" width="0.25" x1="1.72" y1="5.177" x2="1.758" y2="5.084"/>
<wire layer="21" width="0.25" x1="1.758" y1="5.084" x2="1.782" y2="4.986"/>
<wire layer="21" width="0.25" x1="1.782" y1="4.986" x2="1.79" y2="4.885"/>
<wire layer="21" width="0.25" x1="1.79" y1="4.885" x2="1.782" y2="4.784"/>
<wire layer="21" width="0.25" x1="1.782" y1="4.784" x2="1.758" y2="4.686"/>
<wire layer="21" width="0.25" x1="1.758" y1="4.686" x2="1.72" y2="4.592"/>
<wire layer="21" width="0.25" x1="1.72" y1="4.592" x2="1.667" y2="4.506"/>
<wire layer="21" width="0.25" x1="1.667" y1="4.506" x2="1.601" y2="4.429"/>
<wire layer="21" width="0.25" x1="1.601" y1="4.429" x2="1.524" y2="4.363"/>
<wire layer="21" width="0.25" x1="1.524" y1="4.363" x2="1.438" y2="4.31"/>
<wire layer="21" width="0.25" x1="1.438" y1="4.31" x2="1.344" y2="4.272"/>
<wire layer="21" width="0.25" x1="1.344" y1="4.272" x2="1.246" y2="4.248"/>
<wire layer="21" width="0.25" x1="1.246" y1="4.248" x2="1.145" y2="4.24"/>
<wire layer="21" width="0.25" x1="1.145" y1="4.24" x2="1.086" y2="4.24"/>
<wire layer="21" width="0.25" x1="17.834" y1="4.24" x2="17.733" y2="4.248"/>
<wire layer="21" width="0.25" x1="17.733" y1="4.248" x2="17.635" y2="4.272"/>
<wire layer="21" width="0.25" x1="17.635" y1="4.272" x2="17.542" y2="4.31"/>
<wire layer="21" width="0.25" x1="17.542" y1="4.31" x2="17.455" y2="4.363"/>
<wire layer="21" width="0.25" x1="17.455" y1="4.363" x2="17.378" y2="4.429"/>
<wire layer="21" width="0.25" x1="17.378" y1="4.429" x2="17.313" y2="4.506"/>
<wire layer="21" width="0.25" x1="17.313" y1="4.506" x2="17.26" y2="4.592"/>
<wire layer="21" width="0.25" x1="17.26" y1="4.592" x2="17.221" y2="4.686"/>
<wire layer="21" width="0.25" x1="17.221" y1="4.686" x2="17.198" y2="4.784"/>
<wire layer="21" width="0.25" x1="17.198" y1="4.784" x2="17.19" y2="4.885"/>
<wire layer="21" width="0.25" x1="17.19" y1="4.885" x2="17.198" y2="4.986"/>
<wire layer="21" width="0.25" x1="17.198" y1="4.986" x2="17.221" y2="5.084"/>
<wire layer="21" width="0.25" x1="17.221" y1="5.084" x2="17.26" y2="5.177"/>
<wire layer="21" width="0.25" x1="17.26" y1="5.177" x2="17.313" y2="5.264"/>
<wire layer="21" width="0.25" x1="17.313" y1="5.264" x2="17.378" y2="5.341"/>
<wire layer="21" width="0.25" x1="17.378" y1="5.341" x2="17.455" y2="5.406"/>
<wire layer="21" width="0.25" x1="17.455" y1="5.406" x2="17.542" y2="5.459"/>
<wire layer="21" width="0.25" x1="17.542" y1="5.459" x2="17.635" y2="5.498"/>
<wire layer="21" width="0.25" x1="17.635" y1="5.498" x2="17.733" y2="5.521"/>
<wire layer="21" width="0.25" x1="17.733" y1="5.521" x2="17.834" y2="5.529"/>
<wire layer="21" width="0.25" x1="17.834" y1="5.529" x2="17.896" y2="5.529"/>
<wire layer="21" width="0.25" x1="17.896" y1="5.529" x2="17.997" y2="5.521"/>
<wire layer="21" width="0.25" x1="17.997" y1="5.521" x2="18.095" y2="5.498"/>
<wire layer="21" width="0.25" x1="18.095" y1="5.498" x2="18.188" y2="5.459"/>
<wire layer="21" width="0.25" x1="18.188" y1="5.459" x2="18.275" y2="5.406"/>
<wire layer="21" width="0.25" x1="18.275" y1="5.406" x2="18.352" y2="5.341"/>
<wire layer="21" width="0.25" x1="18.352" y1="5.341" x2="18.417" y2="5.264"/>
<wire layer="21" width="0.25" x1="18.417" y1="5.264" x2="18.47" y2="5.177"/>
<wire layer="21" width="0.25" x1="18.47" y1="5.177" x2="18.509" y2="5.084"/>
<wire layer="21" width="0.25" x1="18.509" y1="5.084" x2="18.532" y2="4.986"/>
<wire layer="21" width="0.25" x1="18.532" y1="4.986" x2="18.54" y2="4.885"/>
<wire layer="21" width="0.25" x1="18.54" y1="4.885" x2="18.532" y2="4.784"/>
<wire layer="21" width="0.25" x1="18.532" y1="4.784" x2="18.509" y2="4.686"/>
<wire layer="21" width="0.25" x1="18.509" y1="4.686" x2="18.47" y2="4.592"/>
<wire layer="21" width="0.25" x1="18.47" y1="4.592" x2="18.417" y2="4.506"/>
<wire layer="21" width="0.25" x1="18.417" y1="4.506" x2="18.352" y2="4.429"/>
<wire layer="21" width="0.25" x1="18.352" y1="4.429" x2="18.275" y2="4.363"/>
<wire layer="21" width="0.25" x1="18.275" y1="4.363" x2="18.188" y2="4.31"/>
<wire layer="21" width="0.25" x1="18.188" y1="4.31" x2="18.095" y2="4.272"/>
<wire layer="21" width="0.25" x1="18.095" y1="4.272" x2="17.997" y2="4.248"/>
<wire layer="21" width="0.25" x1="17.997" y1="4.248" x2="17.896" y2="4.24"/>
<wire layer="21" width="0.25" x1="17.896" y1="4.24" x2="17.834" y2="4.24"/>
<dimension x1="0.715" y1="1.53" x2="18.265" y2="1.53" x3="0.715" y3="-4.06" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="1.89" y1="1.53" x2="2.14" y2="1.53" x3="1.89" y3="-1.69" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="18.265" y1="2.53" x2="18.265" y2="0.53" x3="20.81" y3="2.53" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="1.365" y1="0.53" x2="1.115" y2="4.885" x3="-1.74" y3="0.53" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="17.865" y1="4.885" x2="17.615" y2="0.53" x3="24.43" y3="4.885" layer="51" dtype="vertical" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="1.115" y1="4.885" x2="17.865" y2="4.885" x3="1.115" y3="6.07" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="1.24" y1="1.53" x2="1.115" y2="4.885" x3="1.24" y3="3.73" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
<dimension x1="17.74" y1="1.53" x2="17.865" y2="4.885" x3="17.74" y3="3.73" layer="51" dtype="horizontal" width="0.13" extwidth="0" extlength="0" extoffset="0" textsize="0.54" textratio="10" unit="mm" precision="3" visible="no"/>
</package>
</packages>
<symbols>
<symbol name="DIODE_0402">
<wire layer="94" width="0.25" x1="-2.54" y1="0" x2="-1.6" y2="0"/>
<wire layer="94" width="0.25" x1="1.575" y1="0" x2="2.54" y2="0"/>
<wire layer="94" width="0.25" x1="1.575" y1="-1.905" x2="1.575" y2="1.905"/>
<wire layer="94" width="0.25" x1="1.575" y1="0" x2="-1.6" y2="1.905"/>
<wire layer="94" width="0.25" x1="-1.6" y1="1.905" x2="-1.6" y2="-1.905"/>
<wire layer="94" width="0.25" x1="-1.6" y1="-1.905" x2="1.575" y2="0"/>
<text x="0" y="2.488" size="1.619" layer="95" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>NAME</text>
<pin name="K" visible="pad" length="short" direction="pas" rot="R180" x="5.08" y="0"/>
<pin name="A" visible="pad" length="short" direction="pas" x="-5.08" y="0"/>
</symbol>
<symbol name="GND">
<wire layer="94" width="0.25" x1="-1.905" y1="1.016" x2="1.905" y2="1.016"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-0.508" y1="-1.016" x2="0.508" y2="-1.016"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="GND" visible="pad" length="short" direction="sup" rot="R270" x="0" y="3.556"/>
</symbol>
<symbol name="SCL">
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="1.27"/>
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="-1.27" y2="1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="1.27" x2="-1.27" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="0" y1="-1.27" x2="1.27" y2="0"/>
<text x="-2.083" y="0" size="1.619" layer="96" font="vector" ratio="10" rot="R90" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="SCL_3_0">
<wire layer="94" width="0.25" x1="1.27" y1="0" x2="0" y2="1.27"/>
<wire layer="94" width="0.25" x1="0" y1="1.27" x2="-1.27" y2="1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="1.27" x2="-1.27" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-1.27" y1="-1.27" x2="0" y2="-1.27"/>
<wire layer="94" width="0.25" x1="0" y1="-1.27" x2="1.27" y2="0"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="3.81" y="0"/>
</symbol>
<symbol name="SDA">
<wire layer="94" width="0.25" x1="2.54" y1="0" x2="1.27" y2="1.27"/>
<wire layer="94" width="0.25" x1="1.27" y1="1.27" x2="-2.54" y2="1.27"/>
<wire layer="94" width="0.25" x1="-2.54" y1="1.27" x2="-2.54" y2="-1.27"/>
<wire layer="94" width="0.25" x1="-2.54" y1="-1.27" x2="1.27" y2="-1.27"/>
<wire layer="94" width="0.25" x1="1.27" y1="-1.27" x2="2.54" y2="0"/>
<text x="0" y="-2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="5.08" y="0"/>
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
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="6.35" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-6.35" y="0"/>
</symbol>
<symbol name="CAP_0402">
<wire layer="94" width="0.254" x1="0.944" y1="1.911" x2="0.944" y2="-1.911" curve="74.02156"/>
<wire layer="94" width="0.25" x1="-0.33" y1="-1.905" x2="-0.33" y2="1.905"/>
<wire layer="94" width="0.25" x1="0.305" y1="0" x2="1.27" y2="0"/>
<wire layer="94" width="0.25" x1="-1.27" y1="0" x2="-0.33" y2="0"/>
<text x="0" y="-2.494" size="1.619" layer="95" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>NAME</text>
<pin name="2" visible="pad" length="short" direction="pas" rot="R180" x="3.81" y="0"/>
<pin name="1" visible="pad" length="short" direction="pas" x="-3.81" y="0"/>
</symbol>
<symbol name="ADDRSELECT">
<wire layer="94" width="0.25" x1="-3.81" y1="-1.27" x2="2.54" y2="-1.27"/>
<wire layer="94" width="0.25" x1="2.54" y1="-1.27" x2="3.81" y2="0"/>
<wire layer="94" width="0.25" x1="3.81" y1="0" x2="2.54" y2="1.27"/>
<wire layer="94" width="0.25" x1="2.54" y1="1.27" x2="-3.81" y2="1.27"/>
<wire layer="94" width="0.25" x1="-3.81" y1="1.27" x2="-3.81" y2="-1.27"/>
<text x="-10.16" y="0.457" size="1.619" layer="96" font="vector" ratio="10" rot="R180" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="6.35" y="0"/>
</symbol>
<symbol name="ADDRSELECT_8_0">
<wire layer="94" width="0.25" x1="-3.81" y1="-1.27" x2="2.54" y2="-1.27"/>
<wire layer="94" width="0.25" x1="2.54" y1="-1.27" x2="3.81" y2="0"/>
<wire layer="94" width="0.25" x1="3.81" y1="0" x2="2.54" y2="1.27"/>
<wire layer="94" width="0.25" x1="2.54" y1="1.27" x2="-3.81" y2="1.27"/>
<wire layer="94" width="0.25" x1="-3.81" y1="1.27" x2="-3.81" y2="-1.27"/>
<text x="-4.393" y="-0.23" size="1.619" layer="96" font="vector" ratio="10" rot="R90" align="bottom-center" distance="50">>VALUE</text>
<pin name="1" visible="pad" length="short" direction="sup" rot="R180" x="6.35" y="0"/>
</symbol>
<symbol name="5050700622">
<wire layer="94" width="0.25" x1="-3.81" y1="6.35" x2="3.81" y2="6.35"/>
<wire layer="94" width="0.25" x1="3.81" y1="6.35" x2="3.81" y2="-6.35"/>
<wire layer="94" width="0.25" x1="3.81" y1="-6.35" x2="-3.81" y2="-6.35"/>
<wire layer="94" width="0.25" x1="-3.81" y1="-6.35" x2="-3.81" y2="6.35"/>
<text x="-4.393" y="0" size="1.619" layer="95" font="vector" ratio="10" rot="R90" align="bottom-center" distance="50">>NAME</text>
<pin name="GND" visible="both" length="short" direction="nc" rot="R270" x="-2.54" y="8.89"/>
<pin name="SCL" visible="both" length="short" direction="nc" rot="R270" x="0" y="8.89"/>
<pin name="N/C@1" visible="both" length="short" direction="nc" rot="R270" x="2.54" y="8.89"/>
<pin name="VCC" visible="both" length="short" direction="nc" rot="R90" x="-2.54" y="-8.89"/>
<pin name="SDA" visible="both" length="short" direction="nc" rot="R90" x="0" y="-8.89"/>
<pin name="N/C@2" visible="both" length="short" direction="nc" rot="R90" x="2.54" y="-8.89"/>
</symbol>
<symbol name="VCC">
<wire layer="94" width="0.25" x1="-2.54" y1="0" x2="2.54" y2="0"/>
<text x="0" y="2.083" size="1.619" layer="96" font="vector" ratio="10" rot="R0" align="bottom-center" distance="50">>VALUE</text>
<pin name="VCC" visible="pad" length="short" direction="sup" rot="R90" x="0" y="-2.54"/>
</symbol>
<symbol name="0.83-OLED_28PIN">
<wire layer="94" width="0.25" x1="10.16" y1="12.7" x2="83.82" y2="12.7"/>
<wire layer="94" width="0.25" x1="83.82" y1="12.7" x2="83.82" y2="0"/>
<wire layer="94" width="0.25" x1="83.82" y1="0" x2="10.16" y2="0"/>
<wire layer="94" width="0.25" x1="10.16" y1="0" x2="10.16" y2="12.7"/>
<text x="29.21" y="2.893" size="2.429" layer="94" font="vector" ratio="10" rot="R0" align="top-left" distance="92">DISPLAY CONNECTOR</text>
<pin name="N.C._(GND)@1" visible="both" length="short" direction="nc" rot="R270" x="12.7" y="13.97"/>
<pin name="C2P" visible="both" length="short" direction="nc" rot="R270" x="15.24" y="13.97"/>
<pin name="C2N" visible="both" length="short" direction="nc" rot="R270" x="17.78" y="13.97"/>
<pin name="C1P" visible="both" length="short" direction="nc" rot="R270" x="20.32" y="13.97"/>
<pin name="C1N" visible="both" length="short" direction="nc" rot="R270" x="22.86" y="13.97"/>
<pin name="VDDB" visible="both" length="short" direction="nc" rot="R270" x="25.4" y="13.97"/>
<pin name="VSS" visible="both" length="short" direction="nc" rot="R270" x="27.94" y="13.97"/>
<pin name="VDD" visible="both" length="short" direction="nc" rot="R270" x="30.48" y="13.97"/>
<pin name="BS1" visible="both" length="short" direction="nc" rot="R270" x="33.02" y="13.97"/>
<pin name="BS2" visible="both" length="short" direction="nc" rot="R270" x="35.56" y="13.97"/>
<pin name="CS#" visible="both" length="short" direction="nc" rot="R270" x="38.1" y="13.97"/>
<pin name="RES#" visible="both" length="short" direction="nc" rot="R270" x="40.64" y="13.97"/>
<pin name="D/C#" visible="both" length="short" direction="nc" rot="R270" x="43.18" y="13.97"/>
<pin name="R/W#" visible="both" length="short" direction="nc" rot="R270" x="45.72" y="13.97"/>
<pin name="E/RD#" visible="both" length="short" direction="nc" rot="R270" x="48.26" y="13.97"/>
<pin name="D0" visible="both" length="short" direction="nc" rot="R270" x="50.8" y="13.97"/>
<pin name="D1" visible="both" length="short" direction="nc" rot="R270" x="53.34" y="13.97"/>
<pin name="D2" visible="both" length="short" direction="nc" rot="R270" x="55.88" y="13.97"/>
<pin name="D3" visible="both" length="short" direction="nc" rot="R270" x="58.42" y="13.97"/>
<pin name="D4" visible="both" length="short" direction="nc" rot="R270" x="60.96" y="13.97"/>
<pin name="D5" visible="both" length="short" direction="nc" rot="R270" x="63.5" y="13.97"/>
<pin name="D6" visible="both" length="short" direction="nc" rot="R270" x="66.04" y="13.97"/>
<pin name="D7" visible="both" length="short" direction="nc" rot="R270" x="68.58" y="13.97"/>
<pin name="IREF" visible="both" length="short" direction="nc" rot="R270" x="71.12" y="13.97"/>
<pin name="VCOMH" visible="both" length="short" direction="nc" rot="R270" x="73.66" y="13.97"/>
<pin name="VCC" visible="both" length="short" direction="nc" rot="R270" x="76.2" y="13.97"/>
<pin name="VLSS" visible="both" length="short" direction="nc" rot="R270" x="78.74" y="13.97"/>
<pin name="N.C._(GND)@2" visible="both" length="short" direction="nc" rot="R270" x="81.28" y="13.97"/>
</symbol>
</symbols>
<devicesets>
<deviceset name="DIODE_0402" prefix="D">
<gates>
<gate name="1" symbol="DIODE_0402" x="0" y="0"/>
</gates>
<devices>
<device name="" package="DIO_0402">
<connects>
<connect gate="1" pin="K" pad="1"/>
<connect gate="1" pin="A" pad="2"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="GND" prefix="NetPort">
<gates>
<gate name="1" symbol="GND" x="0" y="0"/>
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
<deviceset name="SCL" prefix="NetPort">
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
<deviceset name="SCL_3" prefix="NetPort">
<gates>
<gate name="1" symbol="SCL_3_0" x="0" y="0"/>
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
<attribute name="VALUE" value="10k"/>
</technology>
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
<attribute name="VALUE" value="1uF"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="ADDRSELECT" prefix="A">
<gates>
<gate name="1" symbol="ADDRSELECT" x="0" y="0"/>
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
<deviceset name="ADDRSELECT_8" prefix="A">
<gates>
<gate name="1" symbol="ADDRSELECT_8_0" x="0" y="0"/>
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
<deviceset name="5050700622" prefix="U">
<gates>
<gate name="1" symbol="5050700622" x="0" y="0"/>
</gates>
<devices>
<device name="" package="5050700622">
<connects>
<connect gate="1" pin="GND" pad="1"/>
<connect gate="1" pin="SCL" pad="2"/>
<connect gate="1" pin="N/C@1" pad="3"/>
<connect gate="1" pin="VCC" pad="4"/>
<connect gate="1" pin="SDA" pad="5"/>
<connect gate="1" pin="N/C@2" pad="6"/>
</connects>
<technologies>
<technology name="">
<attribute name="MANUFACTURER" value="Molex"/>
</technology>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="VCC" prefix="NetPort">
<gates>
<gate name="1" symbol="VCC" x="0" y="0"/>
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
<deviceset name="0.83-OLED_28PIN" prefix="Display_Connector">
<gates>
<gate name="1" symbol="0.83-OLED_28PIN" x="-46.99" y="-6.35"/>
</gates>
<devices>
<device name="" package="0.83-OLED_28PIN">
<connects>
<connect gate="1" pin="N.C._(GND)@1" pad="1"/>
<connect gate="1" pin="C2P" pad="2"/>
<connect gate="1" pin="C2N" pad="3"/>
<connect gate="1" pin="C1P" pad="4"/>
<connect gate="1" pin="C1N" pad="5"/>
<connect gate="1" pin="VDDB" pad="6"/>
<connect gate="1" pin="VSS" pad="7"/>
<connect gate="1" pin="VDD" pad="8"/>
<connect gate="1" pin="BS1" pad="9"/>
<connect gate="1" pin="BS2" pad="10"/>
<connect gate="1" pin="CS#" pad="11"/>
<connect gate="1" pin="RES#" pad="12"/>
<connect gate="1" pin="D/C#" pad="13"/>
<connect gate="1" pin="R/W#" pad="14"/>
<connect gate="1" pin="E/RD#" pad="15"/>
<connect gate="1" pin="D0" pad="16"/>
<connect gate="1" pin="D1" pad="17"/>
<connect gate="1" pin="D2" pad="18"/>
<connect gate="1" pin="D3" pad="19"/>
<connect gate="1" pin="D4" pad="20"/>
<connect gate="1" pin="D5" pad="21"/>
<connect gate="1" pin="D6" pad="22"/>
<connect gate="1" pin="D7" pad="23"/>
<connect gate="1" pin="IREF" pad="24"/>
<connect gate="1" pin="VCOMH" pad="25"/>
<connect gate="1" pin="VCC" pad="26"/>
<connect gate="1" pin="VLSS" pad="27"/>
<connect gate="1" pin="N.C._(GND)@2" pad="28"/>
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
<part name="A1" library="common" deviceset="ADDRSELECT" device="" value="AddrSelect"/>
<part name="A2" library="common" deviceset="ADDRSELECT_8" device="" value="AddrSelect"/>
<part name="C1" library="common" deviceset="CAP_0402" device="" value="1uF"/>
<part name="C2" library="common" deviceset="CAP_0402" device="" value="1uF"/>
<part name="C3" library="common" deviceset="CAP_0402" device="" value="10uF"/>
<part name="C4" library="common" deviceset="CAP_0402" device="" value="4.7uF"/>
<part name="C5" library="common" deviceset="CAP_0402" device="" value="4.7uF"/>
<part name="D1" library="common" deviceset="DIODE_0402" device=""/>
<part name="Display_Connector" library="common" deviceset="0.83-OLED_28PIN" device=""/>
<part name="NetPort1" library="common" deviceset="VCC" device="" value="VCC"/>
<part name="NetPort2" library="common" deviceset="GND" device="" value="GND"/>
<part name="NetPort3" library="common" deviceset="GND" device="" value="GND"/>
<part name="NetPort4" library="common" deviceset="VCC" device="" value="VCC"/>
<part name="NetPort5" library="common" deviceset="GND" device="" value="GND"/>
<part name="NetPort6" library="common" deviceset="VCC" device="" value="VCC"/>
<part name="NetPort7" library="common" deviceset="GND" device="" value="GND"/>
<part name="NetPort8" library="common" deviceset="VCC" device="" value="VCC"/>
<part name="NetPort9" library="common" deviceset="SCL" device="" value="SCL"/>
<part name="NetPort10" library="common" deviceset="SDA" device="" value="SDA"/>
<part name="NetPort11" library="common" deviceset="GND" device="" value="GND"/>
<part name="NetPort12" library="common" deviceset="GND" device="" value="GND"/>
<part name="NetPort14" library="common" deviceset="SCL_3" device="" value="SCL"/>
<part name="NetPort15" library="common" deviceset="SDA" device="" value="SDA"/>
<part name="NetPort19" library="common" deviceset="VCC" device="" value="VCC"/>
<part name="NetPort22" library="common" deviceset="VCC" device="" value="VCC"/>
<part name="R1" library="common" deviceset="RES_0402" device="" value="10k"/>
<part name="R2" library="common" deviceset="RES_0402" device="" value="10k"/>
<part name="R3" library="common" deviceset="RES_0402" device="" value="10k"/>
<part name="R4" library="common" deviceset="RES_0402" device="" value="390k"/>
<part name="R5" library="common" deviceset="RES_0402" device="" value="4.7k"/>
<part name="U2" library="common" deviceset="5050700622" device=""/>
</parts>
<modules/>
<sheets>
<sheet>
<description>Sheet1</description>
<plain>
<wire layer="97" width="0.333" x1="-130.81" y1="36.83" x2="-110.81" y2="36.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="36.83" x2="-110.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="31.83" x2="-130.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="31.83" x2="-130.81" y2="36.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="31.83" x2="-110.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="31.83" x2="-110.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="26.83" x2="-130.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="26.83" x2="-130.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="26.83" x2="-110.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="26.83" x2="-110.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="21.83" x2="-130.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="21.83" x2="-130.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="21.83" x2="-110.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="21.83" x2="-110.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="16.83" x2="-130.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="16.83" x2="-130.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="16.83" x2="-110.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="16.83" x2="-110.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="11.83" x2="-130.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="11.83" x2="-130.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="11.83" x2="-110.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="11.83" x2="-110.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-110.81" y1="3.092" x2="-130.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-130.81" y1="3.092" x2="-130.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-130.81" y1="3.092" x2="-110.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-110.81" y1="3.092" x2="-110.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-1.908" x2="-130.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-130.81" y1="-1.908" x2="-130.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-130.81" y1="-1.908" x2="-110.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-1.908" x2="-110.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-6.908" x2="-130.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-130.81" y1="-6.908" x2="-130.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-130.81" y1="-6.908" x2="-110.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-6.908" x2="-110.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-11.908" x2="-130.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-130.81" y1="-11.908" x2="-130.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-130.81" y1="-11.908" x2="-110.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-11.908" x2="-110.81" y2="-16.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-16.908" x2="-130.81" y2="-16.908"/>
<wire layer="97" width="0.333" x1="-130.81" y1="-16.908" x2="-130.81" y2="-11.908"/>
<text x="-120.81" y="34.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center" distance="92">Name</text>
<text x="-129.81" y="29.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-129.81" y="24.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-129.81" y="19.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">CAP_0402</text>
<text x="-129.81" y="14.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">DIODE_0402</text>
<text x="-129.81" y="7.461" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">0.83-OLED_28Pin</text>
<text x="-129.81" y="0.592" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">RES_0402</text>
<text x="-129.81" y="-4.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">RES_0402</text>
<text x="-129.81" y="-9.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">RES_0402</text>
<text x="-129.81" y="-14.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">5050700622</text>
<wire layer="97" width="0.333" x1="-110.81" y1="36.83" x2="-90.81" y2="36.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="36.83" x2="-90.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="31.83" x2="-110.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="31.83" x2="-110.81" y2="36.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="31.83" x2="-90.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="31.83" x2="-90.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="26.83" x2="-110.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="26.83" x2="-110.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="26.83" x2="-90.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="26.83" x2="-90.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="21.83" x2="-110.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="21.83" x2="-110.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="21.83" x2="-90.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="21.83" x2="-90.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="16.83" x2="-110.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="16.83" x2="-110.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="16.83" x2="-90.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="16.83" x2="-90.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="11.83" x2="-110.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="11.83" x2="-110.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="11.83" x2="-90.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="11.83" x2="-90.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-90.81" y1="3.092" x2="-110.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-110.81" y1="3.092" x2="-110.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-110.81" y1="3.092" x2="-90.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-90.81" y1="3.092" x2="-90.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-1.908" x2="-110.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-1.908" x2="-110.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-1.908" x2="-90.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-1.908" x2="-90.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-6.908" x2="-110.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-6.908" x2="-110.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-6.908" x2="-90.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-6.908" x2="-90.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-11.908" x2="-110.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-11.908" x2="-110.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-11.908" x2="-90.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-11.908" x2="-90.81" y2="-16.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-16.908" x2="-110.81" y2="-16.908"/>
<wire layer="97" width="0.333" x1="-110.81" y1="-16.908" x2="-110.81" y2="-11.908"/>
<text x="-100.81" y="34.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center" distance="92">Value</text>
<text x="-109.81" y="29.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1uF</text>
<text x="-109.81" y="24.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">10uF</text>
<text x="-109.81" y="19.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">4.7uF</text>
<text x="-109.81" y="14.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-109.81" y="7.461" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-109.81" y="0.592" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">10k</text>
<text x="-109.81" y="-4.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">390k</text>
<text x="-109.81" y="-9.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">4.7k</text>
<text x="-109.81" y="-14.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<wire layer="97" width="0.333" x1="-90.81" y1="36.83" x2="-70.81" y2="36.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="36.83" x2="-70.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="31.83" x2="-90.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="31.83" x2="-90.81" y2="36.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="31.83" x2="-70.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="31.83" x2="-70.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="26.83" x2="-90.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="26.83" x2="-90.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="26.83" x2="-70.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="26.83" x2="-70.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="21.83" x2="-90.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="21.83" x2="-90.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="21.83" x2="-70.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="21.83" x2="-70.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="16.83" x2="-90.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="16.83" x2="-90.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="16.83" x2="-70.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="16.83" x2="-70.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="11.83" x2="-90.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="11.83" x2="-90.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="11.83" x2="-70.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="11.83" x2="-70.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-70.81" y1="3.092" x2="-90.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-90.81" y1="3.092" x2="-90.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-90.81" y1="3.092" x2="-70.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-70.81" y1="3.092" x2="-70.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-1.908" x2="-90.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-1.908" x2="-90.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-1.908" x2="-70.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-1.908" x2="-70.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-6.908" x2="-90.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-6.908" x2="-90.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-6.908" x2="-70.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-6.908" x2="-70.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-11.908" x2="-90.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-11.908" x2="-90.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-11.908" x2="-70.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-11.908" x2="-70.81" y2="-16.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-16.908" x2="-90.81" y2="-16.908"/>
<wire layer="97" width="0.333" x1="-90.81" y1="-16.908" x2="-90.81" y2="-11.908"/>
<text x="-80.81" y="34.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center" distance="92">Manufacturer</text>
<text x="-89.81" y="29.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-89.81" y="24.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-89.81" y="19.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-89.81" y="14.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-89.81" y="7.461" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-89.81" y="0.592" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-89.81" y="-4.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-89.81" y="-9.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92"></text>
<text x="-89.81" y="-14.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">Molex</text>
<wire layer="97" width="0.333" x1="-70.81" y1="36.83" x2="-50.81" y2="36.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="36.83" x2="-50.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="31.83" x2="-70.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="31.83" x2="-70.81" y2="36.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="31.83" x2="-50.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="31.83" x2="-50.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="26.83" x2="-70.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="26.83" x2="-70.81" y2="31.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="26.83" x2="-50.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="26.83" x2="-50.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="21.83" x2="-70.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="21.83" x2="-70.81" y2="26.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="21.83" x2="-50.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="21.83" x2="-50.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="16.83" x2="-70.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="16.83" x2="-70.81" y2="21.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="16.83" x2="-50.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="16.83" x2="-50.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="11.83" x2="-70.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="11.83" x2="-70.81" y2="16.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="11.83" x2="-50.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-50.81" y1="11.83" x2="-50.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-50.81" y1="3.092" x2="-70.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-70.81" y1="3.092" x2="-70.81" y2="11.83"/>
<wire layer="97" width="0.333" x1="-70.81" y1="3.092" x2="-50.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-50.81" y1="3.092" x2="-50.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-50.81" y1="-1.908" x2="-70.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-1.908" x2="-70.81" y2="3.092"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-1.908" x2="-50.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-50.81" y1="-1.908" x2="-50.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-50.81" y1="-6.908" x2="-70.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-6.908" x2="-70.81" y2="-1.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-6.908" x2="-50.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-50.81" y1="-6.908" x2="-50.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-50.81" y1="-11.908" x2="-70.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-11.908" x2="-70.81" y2="-6.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-11.908" x2="-50.81" y2="-11.908"/>
<wire layer="97" width="0.333" x1="-50.81" y1="-11.908" x2="-50.81" y2="-16.908"/>
<wire layer="97" width="0.333" x1="-50.81" y1="-16.908" x2="-70.81" y2="-16.908"/>
<wire layer="97" width="0.333" x1="-70.81" y1="-16.908" x2="-70.81" y2="-11.908"/>
<text x="-60.81" y="34.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center" distance="92">Quantity</text>
<text x="-69.81" y="29.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">2</text>
<text x="-69.81" y="24.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-69.81" y="19.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">2</text>
<text x="-69.81" y="14.33" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-69.81" y="7.461" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-69.81" y="0.592" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">3</text>
<text x="-69.81" y="-4.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-69.81" y="-9.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
<text x="-69.81" y="-14.408" size="2.159" layer="97" font="vector" ratio="10" rot="R0" align="center-left" distance="92">1</text>
</plain>
<moduleinsts/>
<instances>
<instance part="A1" gate="1" x="-16.51" y="8.89" rot="R180.000420918452"/>
<instance part="A2" gate="1" x="114.3" y="57.15" rot="R270.000631377677"/>
<instance part="C1" gate="1" x="-11.43" y="40.64" rot="R270.000631377677"/>
<instance part="C2" gate="1" x="-2.54" y="40.64" rot="R270.000631377677"/>
<instance part="C3" gate="1" x="31.75" y="24.13" rot="R270.000631377677"/>
<instance part="C4" gate="1" x="99.06" y="1.27" rot="R270.000631377677"/>
<instance part="C5" gate="1" x="106.68" y="1.27" rot="R270.000631377677"/>
<instance part="D1" gate="1" x="39.37" y="11.43"/>
<instance part="Display_Connector" gate="1" x="-40.327" y="52.07" rot="R270.000631377677"/>
<instance part="NetPort1" gate="1" x="2.54" y="33.02"/>
<instance part="NetPort2" gate="1" x="-21.59" y="46.736" rot="R180.000420918452"/>
<instance part="NetPort3" gate="1" x="10.16" y="34.036" rot="R180.000420918452"/>
<instance part="NetPort4" gate="1" x="17.78" y="33.02"/>
<instance part="NetPort5" gate="1" x="25.4" y="34.036" rot="R180.000420918452"/>
<instance part="NetPort6" gate="1" x="48.26" y="33.02"/>
<instance part="NetPort7" gate="1" x="55.88" y="34.036" rot="R180.000420918452"/>
<instance part="NetPort8" gate="1" x="69.85" y="33.02"/>
<instance part="NetPort9" gate="1" x="62.23" y="31.75" rot="R270.000631377677"/>
<instance part="NetPort10" gate="1" x="80.01" y="30.48" rot="R270.000631377677"/>
<instance part="NetPort11" gate="1" x="86.36" y="34.036" rot="R180.000420918452"/>
<instance part="NetPort12" gate="1" x="10.16" y="86.106" rot="R180.000420918452"/>
<instance part="NetPort14" gate="1" x="24.13" y="82.55" rot="R180.000420918452"/>
<instance part="NetPort15" gate="1" x="22.86" y="50.8" rot="R180.000420918452"/>
<instance part="NetPort19" gate="1" x="100.33" y="60.96"/>
<instance part="NetPort22" gate="1" x="-1.27" y="62.23"/>
<instance part="R1" gate="1" x="39.37" y="19.05"/>
<instance part="R2" gate="1" x="69.85" y="15.24" rot="R90.0002104592258"/>
<instance part="R3" gate="1" x="76.2" y="15.24" rot="R90.0002104592258"/>
<instance part="R4" gate="1" x="91.44" y="1.27" rot="R90.0002104592258"/>
<instance part="R5" gate="1" x="100.33" y="49.53" rot="R90.0002104592258"/>
<instance part="U2" gate="1" x="12.7" y="66.04"/>
</instances>
<busses/>
<nets>
<net name="Net_0" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="39.37" x2="-21.59" y2="39.37"/>
<wire layer="91" width="0.1" x1="-21.59" y1="39.37" x2="-21.59" y2="43.18"/>
<pinref part="Display_Connector" gate="1" pin="N.C._(GND)@1"/>
<pinref part="NetPort2" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="24.13" x2="10.16" y2="24.13"/>
<wire layer="91" width="0.1" x1="10.16" y1="24.13" x2="10.16" y2="30.48"/>
<pinref part="Display_Connector" gate="1" pin="VSS"/>
<pinref part="NetPort3" gate="1" pin="GND"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="16.51" x2="25.4" y2="16.51"/>
<wire layer="91" width="0.1" x1="25.4" y1="29.21" x2="25.4" y2="30.48"/>
<wire layer="91" width="0.1" x1="25.4" y1="16.51" x2="25.4" y2="29.21"/>
<pinref part="Display_Connector" gate="1" pin="BS2"/>
<pinref part="NetPort5" gate="1" pin="GND"/>
<wire layer="91" width="0.1" x1="31.75" y1="29.21" x2="31.75" y2="27.94"/>
<wire layer="91" width="0.1" x1="31.75" y1="29.21" x2="25.4" y2="29.21"/>
<pinref part="C3" gate="1" pin="1"/>
<junction x="25.4" y="29.21"/>
<wire layer="91" width="0.1" x1="-26.357" y1="13.97" x2="25.4" y2="13.97"/>
<wire layer="91" width="0.1" x1="25.4" y1="13.97" x2="25.4" y2="16.51"/>
<pinref part="Display_Connector" gate="1" pin="CS#"/>
<junction x="25.4" y="16.51"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="-6.35" x2="86.36" y2="-6.35"/>
<wire layer="91" width="0.1" x1="86.36" y1="29.21" x2="86.36" y2="30.48"/>
<wire layer="91" width="0.1" x1="86.36" y1="-6.35" x2="86.36" y2="29.21"/>
<pinref part="Display_Connector" gate="1" pin="D3"/>
<pinref part="NetPort11" gate="1" pin="GND"/>
<wire layer="91" width="0.1" x1="-26.357" y1="-8.89" x2="86.36" y2="-8.89"/>
<wire layer="91" width="0.1" x1="86.36" y1="-8.89" x2="86.36" y2="-6.35"/>
<pinref part="Display_Connector" gate="1" pin="D4"/>
<junction x="86.36" y="-6.35"/>
<wire layer="91" width="0.1" x1="-26.357" y1="-11.43" x2="86.36" y2="-11.43"/>
<wire layer="91" width="0.1" x1="86.36" y1="-11.43" x2="86.36" y2="-8.89"/>
<pinref part="Display_Connector" gate="1" pin="D5"/>
<junction x="86.36" y="-8.89"/>
<wire layer="91" width="0.1" x1="-26.357" y1="-13.97" x2="86.36" y2="-13.97"/>
<wire layer="91" width="0.1" x1="86.36" y1="-13.97" x2="86.36" y2="-11.43"/>
<pinref part="Display_Connector" gate="1" pin="D6"/>
<junction x="86.36" y="-11.43"/>
<wire layer="91" width="0.1" x1="-26.357" y1="-16.51" x2="86.36" y2="-16.51"/>
<wire layer="91" width="0.1" x1="86.36" y1="-16.51" x2="86.36" y2="-13.97"/>
<pinref part="Display_Connector" gate="1" pin="D7"/>
<junction x="86.36" y="-13.97"/>
<wire layer="91" width="0.1" x1="91.44" y1="22.86" x2="91.44" y2="29.21"/>
<wire layer="91" width="0.1" x1="91.44" y1="7.62" x2="91.44" y2="22.86"/>
<wire layer="91" width="0.1" x1="91.44" y1="29.21" x2="86.36" y2="29.21"/>
<pinref part="R4" gate="1" pin="2"/>
<junction x="86.36" y="29.21"/>
<wire layer="91" width="0.1" x1="99.06" y1="5.08" x2="99.06" y2="22.86"/>
<wire layer="91" width="0.1" x1="99.06" y1="22.86" x2="91.44" y2="22.86"/>
<pinref part="C4" gate="1" pin="1"/>
<junction x="91.44" y="22.86"/>
<wire layer="91" width="0.1" x1="106.68" y1="5.08" x2="106.68" y2="22.86"/>
<wire layer="91" width="0.1" x1="106.68" y1="22.86" x2="99.06" y2="22.86"/>
<pinref part="C5" gate="1" pin="1"/>
<junction x="99.06" y="22.86"/>
<wire layer="91" width="0.1" x1="-26.357" y1="-26.67" x2="118.11" y2="-26.67"/>
<wire layer="91" width="0.1" x1="118.11" y1="-26.67" x2="118.11" y2="22.86"/>
<wire layer="91" width="0.1" x1="118.11" y1="22.86" x2="106.68" y2="22.86"/>
<pinref part="Display_Connector" gate="1" pin="VLSS"/>
<junction x="106.68" y="22.86"/>
<wire layer="91" width="0.1" x1="-26.357" y1="-29.21" x2="118.11" y2="-29.21"/>
<wire layer="91" width="0.1" x1="118.11" y1="-29.21" x2="118.11" y2="-26.67"/>
<pinref part="Display_Connector" gate="1" pin="N.C._(GND)@2"/>
<junction x="118.11" y="-26.67"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="55.88" y1="30.48" x2="55.88" y2="6.35"/>
<wire layer="91" width="0.1" x1="55.88" y1="6.35" x2="-26.357" y2="6.35"/>
<pinref part="NetPort7" gate="1" pin="GND"/>
<pinref part="Display_Connector" gate="1" pin="R/W#"/>
<wire layer="91" width="0.1" x1="-26.357" y1="3.81" x2="55.88" y2="3.81"/>
<wire layer="91" width="0.1" x1="55.88" y1="3.81" x2="55.88" y2="6.35"/>
<pinref part="Display_Connector" gate="1" pin="E/RD#"/>
<junction x="55.88" y="6.35"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="10.16" y1="82.55" x2="10.16" y2="74.93"/>
<pinref part="NetPort12" gate="1" pin="GND"/>
<pinref part="U2" gate="1" pin="GND"/>
</segment>
</net>
<net name="Net_1" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="36.83" x2="-17.78" y2="36.83"/>
<wire layer="91" width="0.1" x1="-17.78" y1="36.83" x2="-17.78" y2="45.72"/>
<wire layer="91" width="0.1" x1="-11.43" y1="45.72" x2="-11.43" y2="44.45"/>
<wire layer="91" width="0.1" x1="-17.78" y1="45.72" x2="-11.43" y2="45.72"/>
<pinref part="Display_Connector" gate="1" pin="C2P"/>
<pinref part="C1" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_2" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="34.29" x2="-11.43" y2="34.29"/>
<wire layer="91" width="0.1" x1="-11.43" y1="34.29" x2="-11.43" y2="36.83"/>
<pinref part="Display_Connector" gate="1" pin="C2N"/>
<pinref part="C1" gate="1" pin="2"/>
</segment>
</net>
<net name="Net_3" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="31.75" x2="-7.62" y2="31.75"/>
<wire layer="91" width="0.1" x1="-7.62" y1="31.75" x2="-7.62" y2="45.72"/>
<wire layer="91" width="0.1" x1="-2.54" y1="45.72" x2="-2.54" y2="44.45"/>
<wire layer="91" width="0.1" x1="-7.62" y1="45.72" x2="-2.54" y2="45.72"/>
<pinref part="Display_Connector" gate="1" pin="C1P"/>
<pinref part="C2" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_4" class="0">
<segment>
<wire layer="91" width="0.1" x1="-2.54" y1="36.83" x2="-2.54" y2="29.21"/>
<wire layer="91" width="0.1" x1="-2.54" y1="29.21" x2="-26.357" y2="29.21"/>
<pinref part="C2" gate="1" pin="2"/>
<pinref part="Display_Connector" gate="1" pin="C1N"/>
</segment>
</net>
<net name="Net_5" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="26.67" x2="2.54" y2="26.67"/>
<wire layer="91" width="0.1" x1="2.54" y1="26.67" x2="2.54" y2="30.48"/>
<pinref part="Display_Connector" gate="1" pin="VDDB"/>
<pinref part="NetPort1" gate="1" pin="VCC"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="21.59" x2="17.78" y2="21.59"/>
<wire layer="91" width="0.1" x1="17.78" y1="21.59" x2="17.78" y2="30.48"/>
<pinref part="Display_Connector" gate="1" pin="VDD"/>
<pinref part="NetPort4" gate="1" pin="VCC"/>
<wire layer="91" width="0.1" x1="-26.357" y1="19.05" x2="17.78" y2="19.05"/>
<wire layer="91" width="0.1" x1="17.78" y1="19.05" x2="17.78" y2="21.59"/>
<pinref part="Display_Connector" gate="1" pin="BS1"/>
<junction x="17.78" y="21.59"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="48.26" y1="30.48" x2="48.26" y2="19.05"/>
<wire layer="91" width="0.1" x1="48.26" y1="19.05" x2="45.72" y2="19.05"/>
<pinref part="NetPort6" gate="1" pin="VCC"/>
<pinref part="R1" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="44.45" y1="11.43" x2="48.26" y2="11.43"/>
<wire layer="91" width="0.1" x1="48.26" y1="11.43" x2="48.26" y2="19.05"/>
<pinref part="D1" gate="1" pin="K"/>
<junction x="48.26" y="19.05"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="69.85" y1="25.4" x2="69.85" y2="21.59"/>
<wire layer="91" width="0.1" x1="69.85" y1="30.48" x2="69.85" y2="25.4"/>
<pinref part="NetPort8" gate="1" pin="VCC"/>
<pinref part="R2" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="76.2" y1="21.59" x2="76.2" y2="25.4"/>
<wire layer="91" width="0.1" x1="76.2" y1="25.4" x2="69.85" y2="25.4"/>
<pinref part="R3" gate="1" pin="2"/>
<junction x="69.85" y="25.4"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="100.33" y1="55.88" x2="100.33" y2="58.42"/>
<pinref part="R5" gate="1" pin="2"/>
<pinref part="NetPort19" gate="1" pin="VCC"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="-1.27" y1="59.69" x2="-1.27" y2="53.34"/>
<wire layer="91" width="0.1" x1="-1.27" y1="53.34" x2="10.16" y2="53.34"/>
<wire layer="91" width="0.1" x1="10.16" y1="53.34" x2="10.16" y2="57.15"/>
<pinref part="NetPort22" gate="1" pin="VCC"/>
<pinref part="U2" gate="1" pin="VCC"/>
</segment>
</net>
<net name="Net_6" class="0">
<segment>
<wire layer="91" width="0.1" x1="33.02" y1="19.05" x2="31.75" y2="20.32"/>
<pinref part="R1" gate="1" pin="1"/>
<pinref part="C3" gate="1" pin="2"/>
<wire layer="91" width="0.1" x1="34.29" y1="11.43" x2="31.75" y2="11.43"/>
<wire layer="91" width="0.1" x1="31.75" y1="11.43" x2="31.75" y2="19.05"/>
<pinref part="D1" gate="1" pin="A"/>
<junction x="31.75" y="19.05"/>
<wire layer="91" width="0.1" x1="-26.357" y1="11.43" x2="31.75" y2="11.43"/>
<pinref part="Display_Connector" gate="1" pin="RES#"/>
<junction x="31.75" y="11.43"/>
</segment>
</net>
<net name="Net_7" class="0">
<segment>
<wire layer="91" width="0.1" x1="62.23" y1="27.94" x2="62.23" y2="1.27"/>
<wire layer="91" width="0.1" x1="62.23" y1="1.27" x2="-26.357" y2="1.27"/>
<pinref part="NetPort9" gate="1" pin="1"/>
<pinref part="Display_Connector" gate="1" pin="D0"/>
<wire layer="91" width="0.1" x1="69.85" y1="8.89" x2="69.85" y2="1.27"/>
<wire layer="91" width="0.1" x1="69.85" y1="1.27" x2="62.23" y2="1.27"/>
<pinref part="R2" gate="1" pin="1"/>
<junction x="62.23" y="1.27"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="12.7" y1="74.93" x2="12.7" y2="82.55"/>
<wire layer="91" width="0.1" x1="12.7" y1="82.55" x2="20.32" y2="82.55"/>
<pinref part="U2" gate="1" pin="SCL"/>
<pinref part="NetPort14" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_8" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="-1.27" x2="80.01" y2="-1.27"/>
<wire layer="91" width="0.1" x1="80.01" y1="-1.27" x2="80.01" y2="1.27"/>
<wire layer="91" width="0.1" x1="80.01" y1="1.27" x2="80.01" y2="-1.27"/>
<wire layer="91" width="0.1" x1="80.01" y1="-1.27" x2="80.01" y2="25.4"/>
<pinref part="Display_Connector" gate="1" pin="D1"/>
<pinref part="NetPort10" gate="1" pin="1"/>
<wire layer="91" width="0.1" x1="-26.357" y1="-3.81" x2="80.01" y2="-3.81"/>
<wire layer="91" width="0.1" x1="80.01" y1="-3.81" x2="80.01" y2="-1.27"/>
<pinref part="Display_Connector" gate="1" pin="D2"/>
<junction x="80.01" y="-1.27"/>
<wire layer="91" width="0.1" x1="76.2" y1="8.89" x2="76.2" y2="1.27"/>
<wire layer="91" width="0.1" x1="76.2" y1="1.27" x2="80.01" y2="1.27"/>
<pinref part="R3" gate="1" pin="1"/>
<junction x="80.01" y="1.27"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="12.7" y1="57.15" x2="12.7" y2="50.8"/>
<wire layer="91" width="0.1" x1="12.7" y1="50.8" x2="17.78" y2="50.8"/>
<pinref part="U2" gate="1" pin="SDA"/>
<pinref part="NetPort15" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_9" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="-19.05" x2="91.44" y2="-19.05"/>
<wire layer="91" width="0.1" x1="91.44" y1="-19.05" x2="91.44" y2="-5.08"/>
<pinref part="Display_Connector" gate="1" pin="IREF"/>
<pinref part="R4" gate="1" pin="1"/>
</segment>
</net>
<net name="Net_10" class="0">
<segment>
<wire layer="91" width="0.1" x1="99.06" y1="-2.54" x2="99.06" y2="-21.59"/>
<wire layer="91" width="0.1" x1="99.06" y1="-21.59" x2="-26.357" y2="-21.59"/>
<pinref part="C4" gate="1" pin="2"/>
<pinref part="Display_Connector" gate="1" pin="VCOMH"/>
</segment>
</net>
<net name="Net_11" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="-24.13" x2="106.68" y2="-24.13"/>
<wire layer="91" width="0.1" x1="106.68" y1="-24.13" x2="106.68" y2="-2.54"/>
<pinref part="Display_Connector" gate="1" pin="VCC"/>
<pinref part="C5" gate="1" pin="2"/>
</segment>
</net>
<net name="Net_13" class="0">
<segment>
<wire layer="91" width="0.1" x1="-26.357" y1="8.89" x2="-22.86" y2="8.89"/>
<pinref part="Display_Connector" gate="1" pin="D/C#"/>
<pinref part="A1" gate="1" pin="1"/>
</segment>
<segment>
<wire layer="91" width="0.1" x1="100.33" y1="43.18" x2="100.33" y2="36.83"/>
<wire layer="91" width="0.1" x1="100.33" y1="36.83" x2="114.3" y2="36.83"/>
<wire layer="91" width="0.1" x1="114.3" y1="36.83" x2="114.3" y2="50.8"/>
<pinref part="R5" gate="1" pin="1"/>
<pinref part="A2" gate="1" pin="1"/>
</segment>
</net>
</nets>
</sheet>
</sheets>
</schematic>
</drawing>
</eagle>
