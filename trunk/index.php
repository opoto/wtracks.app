<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <META name="keywords"  
          content="GoogleMaps, Map, GPX, track, editor, online, GPS, upload, save, DHTML">
    <title>WTracks - Online GPX track editor</title>
    <style type="text/css">
    v\:* {
      behavior:url(#default#VML);
    }
    .ptlabel {background-color:#ffffff}

    th {
      vertical-align: middle;
      text-align: right;
      background-color: #ddd;
      padding-right:5px;
      padding-left:5px;
      font-family:sans-serif;
      font-size:10pt;
    }

    .title {
      text-align: center; 
      font-size:12pt;
      border: 1px solid black;
    }
    
    .hidden {display: none}

    .options-box{
      background: #eee;
      border: 1px solid black;
      padding: 10px;
      position: absolute;
      left: 10px;
      top: 75px;
      /*width: 500px;*/
      /*height: 250px;*/
      visibility: hidden;
      overflow:auto;
    }

    .mapsize-box{
      background: #eee;
      border: 1px solid black;
      position: absolute;
      left: 35px;
      overflow:auto;
    }

    .graph-box{
      background: #eee;
      border: 1px solid black;
      padding: 10px;
      position: absolute;
      left: 10px;
      top: 150px;
      /*width: 500px;*/
      /*height: 250px;*/
      visibility: hidden;
      overflow:auto;
    }

    </style>
    <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=<?= file_get_contents('private/gmaps.key');?>"
            type="text/javascript"></script>

  </head>
  <body onload="wt_load()" onunload="GUnload()">

<?php 
  $host = $_SERVER["HTTP_HOST"];
  $goto = "goto=".urlencode($_SERVER['REQUEST_URI']);
  $rpxnow_token_url = "/login.php?".$goto;
  $testing = strpos($PHP_SELF, "testing");
  $file = $HTTP_POST_FILES['gpxfile']['tmp_name'];
  $file_name = $HTTP_POST_FILES['gpxfile']['name'];
  $showmarkers = !($_REQUEST["marks"] == "false");
  $showlabels = !($_REQUEST["labels"] == "false");
?>

<!-- =================== Top bar =================== -->

<table width="100%"><tr><td style="text-align:left" width="33%">
<strong>GPX track:</strong>
<a href="javascript:clear_track();">New</a>
| <a href="javascript:show_load_box()">Load</a>
| <a href="javascript:show_save_box()">Save</a>

</td><td style="text-align:center" width="33%">
<span id="message"><img src='img/processing.gif'> Initializing...</span>
</td><td style="text-align:right" width="33%">

<!-- OpenID login (rpxnow) -->
<?php
  $openID = $_COOKIE["LoginOpenID"];
  if ($openID == "") {
?>
<a class="rpxnow" onclick="return false;"
   href="https://wtracks-exofire.rpxnow.com/openid/v2/signin?token_url=<?=$rpxnow_token_url?>">
  <img src="http://wiki.openid.net/f/openid-16x16.gif" alt="" border="0"> Sign In
</a>
<?php
  } else {
      $openID = json_decode(urldecode($openID));
      $name = $openID->profile->displayName;
      $oid = $openID->profile->identifier;
      if ($name == "") {
        $name = str_ireplace("http://", "", $oid);
      }
      echo "<a href='".$openID->profile->identifier."'>".$name;
      echo "</a> | <a href='login.php?action=logout&".$goto."'>Logout</a><br>\n";
  }
?>
<!-- OpenID login (rpxnow) -->

</td></tr></table>
<!-- =================== end of Top bar =================== -->

    <table width="100%">
      <tr>
        <form action="#" onsubmit="wt_showAddress(this.address.value); return false">
        <th style="text-align:left;">
          <strong>Go to:</strong>
          <input type="text" size="20" name="address" value=""/>
          <input type="submit" value="Go!"/>
        </th>
        </form>
        <th class="title" id="trktitle"></th>
        <form action="#">
        <th style="text-align:right">
            Show: <img src="img/mm_20_red.png" alt="handles" title="handles"/>
            <input type="checkbox" id="showmarkers"
            <?php if ($showmarkers) echo "checked"; ?> 
            onclick="wt_showTrkMarkers(this.checked)" />
            &nbsp;/&nbsp; Labels
            <input type="checkbox" id="showlabels"
            <?php if ($showlabels) echo "checked"; ?> 
            onclick="wt_showLabels(this.checked)" />
            &nbsp;/&nbsp; <img src="img/icon13noshade.gif" alt="waypoints" title="waypoints"/>
            <input type="checkbox" id="showwaypoints" checked
            onclick="wt_showWaypoints(this.checked)" />
        </th>
        </form>
      </tr>
    </table>
    <div id="map" style="width: 100%; height: 600px"></div>
    
    <table>
      <tr>
        <th width="200">Distance</th>
        <td width="150">
          <img src='img/oneway.gif' alt='One Way' title='One Way'>
          <span id="distow"></span>
        </td>
        <td width="150">
          <img src='img/roundtrip.gif' alt='Round Trip' title='Round Trip'>
          <span id="distrt"></span>
        </td>
        <th width="150">Altitude Max</th>
        <td width="60" id="altmax">
        </td>
        <th width="150">Climbing</th>
        <td width="60" id="climbing">
        </td><!-- name="submit" value="submit" -->
        <td rowspan="2"><button type="submit" onclick="wt_doGraph(); return false">2D Profile<br><img src="img/2d.gif"></button></td>
      <tr>
        <form action="#">
        <th>
          Duration
          <select name="speedprofile" id="speedprofile" size="1" 
                  onchange="wt_updateSpeedProfile(); wt_update_infos()" >
          </select>
        </th>
        </form>
        <td>
          <img src='img/oneway.gif' alt='One Way' title='One Way'>
          <span id="timeow"></span>
        </td>
        <td>
          <img src='img/roundtrip.gif' alt='Round Trip' title='Round Trip'>
          <span id="timert"></span>
        </td>
        <th>Altitude Min</th>
        <td id="altmin">
        </td>
        <th>Descent</th>
        <td id="descent">
        </td>
      </tr>
      <tr <?php if (! $testing) echo "style='display: none'" ?> >
        <form action="#" onsubmit="debug.set(''); return false">
        <td>
          <input type="submit" value="Clear debug" />
        </td>
        </form>
        <td colspan="6" id="debug">
        </td>
      </tr>
    </table>

    <div class="graph-box" id="graph-box" onkeypress='check_for_escape(event, "graph-box")'>
      <table>
        <tr>
          <th style="text-align:left">Track profile</th>
          <th align="right"><a href="javascript:close_popup('graph-box')">
              <img src="img/close.gif" alt="Close" title="Close" style="border: 0px"/></a></span></th>
        </tr>
        <tr><td colspan="2">
        <div><canvas id="graph" height="350" width="650"></canvas></div>
        </td></tr>
      </table>
    </div>

    <div class="options-box" id="load-box" onkeypress='check_for_escape(event, "load-box")'>
      <table>
        <tr>
          <th style="text-align:left">Load Options</th>
          <th><a href="javascript:close_popup('load-box')"><img src="img/close.gif" alt="Cancel and Close" title="Cancel and Close" style="border: 0px"/></a></span></th>
        </tr>
        <tr>
          <form onsubmit="wt_loadGPX(this.url.value); return false;">
            <td>
              <input type="submit" value="Load GPX from URL:" />
            </td><td>
              <input id="gpxurl" type="text" size="60" name="url" value="tracks/everest.gpx" />
            </td>
          </form>
        </tr>
        <tr>
          <form id="upform" enctype="multipart/form-data" method="post">
            <td>
              <input name="gpxupload" type="submit" value="Load GPX from file:"
                     onclick="return wt_check_fileupload(document.getElementById('upform'));" />
            </td><td>
              <input type="file" size="50" name="gpxfile" id="gpxfile" />
              <input type="hidden" name="marks" value="" />
              <input type="hidden" name="labels" value="" />
            </td>
          </form>
        </tr>
<?php
if ($oid != "") {
?>
        <tr>
          <form onsubmit="return false;">
            <td>
              <input type="submit" value="Your saved track:" id="loadusertrack" onclick="wt_loadGPX(document.getElementById('usertracks').value);""/>
            </td><td>
              <span id="usertracks-span"><select name='url' id='usertracks'></select></span>
              <input type="submit" value="Delete this track" id="deleteusertrack" onclick="delete_track(document.getElementById('usertracks').value);"/>
            </td>
        </tr>
<?php
}
?>
      </table>
    </div>

    <div class="mapsize-box" style="top: 355px">
      <a href="javascript:addMapHeight(20)" title="Increase map size"><img src="img/bigger.png" alt="bigger" border=0></a></td>
    </div>
    <div class="mapsize-box" style="top: 380px">
      <a href="javascript:addMapHeight(-20)" title="Decrease map size"><img src="img/smaller.png" alt="smaller" border=0></a></td>
    </div>

    <div class="options-box" id="save-box" onkeypress='check_for_escape(event, "save-box")'>
      <table>
        <tr>
          <th style="text-align:left">Save Options</th>
          <th><a href="javascript:close_popup('save-box')"><img src="img/close.gif" 
               alt="Cancel and Close" title="Cancel and Close" style="border: 0px"/></a></span></th>
        </tr>
        <tr>
          <td>Track Name</td>
          <form><td><input type="text" size="40" id="trackname"/></td></form>
        </tr>
        <tr>
          <form><td align="right"><input type="checkbox" id="savealt"/></td></form>
          <td>Save intermediate computed altitudes?</td>
        </tr>
        <tr>
          <form><td align="right"><input type="checkbox" id="savetime"/></td></form>
          <td>Save computed timings?</td>
        </tr>
        <tr>
          <form target="_blank" action="savegpx.php" method="post" onSubmit="wt_doSave();">
            <td colspan="2">
              <input type='hidden' id='savedname' name='savedname' value='' />
              <input type="submit" name="action" value="Save" />
<?php
if ($oid != "") {
            echo "<input type='hidden' name='oid' value='".$oid."' />";
            echo "<input type='submit' name='action' value='Save on this server' />";
} else {
           echo "(Sign in to be able to save on this server)";
}
?>
              <textarea name="gpxarea" class="hidden" 
                        id="gpxarea" readonly rows="20" cols="80"><?php
  if ($file<>'') {
    @readfile($file); // 
  }
?></textarea>
            </td>
          </form>
        </tr>
      </table>
    </div>
<?php
  include ('private/local.php');
?>

</body>

    <script type="text/javascript">
    //<![CDATA[

  var speed_profiles = [];

  var wpts = []
  var trkpts = []
  var points = [];
  var polyline = null;
  var current_trkpt
  var speedProfile;
  var minalt = 0
  var maxalt = 0
  var descent = 0
  var climbing = 0
  var trackname = ""
  var isroundtrip = true;
    
  var map;
  var geocoder;
  var clusterer;
  
  var info; // info line
  var debug; // debug area

  var ROUNDTRIP_IMG = "<img src='img/roundtrip.png' alt='Round Trip' title='Round Trip'>";
  var ONEWAY_IMG = "<img src='img/oneway.png' alt='One Way' title='One Way'>";
  var WTRACKS = "WTracks - Online GPX track editor"

  //  wpt icon
  var wp_icon = new GIcon(G_DEFAULT_ICON);
  wp_icon.image            = "img/icon13.png"; // http://maps.google.com/mapfiles/kml/pal2/
  wp_icon.shadow           = "img/icon13s.png";
  wp_icon.iconSize         = new GSize(32,32);
  wp_icon.shadowSize       = new GSize(56,32);
  wp_icon.iconAnchor       = new GPoint(16, 32);
  wp_icon.infoWindowAnchor = new GPoint(16, 0);

  //  wpt icon
  var trkpt_icon = new GIcon(G_DEFAULT_ICON);
  trkpt_icon.image            = "img/mm_20_red.png";
  trkpt_icon.shadow           = "img/mm_20_shadow.png";
  trkpt_icon.iconSize         = new GSize(12, 20);
  trkpt_icon.shadowSize       = new GSize(22, 20);
  trkpt_icon.iconAnchor       = new GPoint(6, 20);
  trkpt_icon.infoWindowAnchor = new GPoint(5, 1);

  /*------------ Utility functions -----------*/

  function getAltitude(lat, lng) {
    // http://ws.geonames.org/srtm3?lat=<lat>&lng=<lng>
    var url = "http://ws.geonames.org/srtm3?lat="+lat+"&lng="+lng

    var request = Lokris.AjaxCall("httprawget_proxy.php?"+url, null, {async: false});
    debug.add("#")
    //debug.add(" status:" + request.status)
    //debug.add(" text: " + request.responseText)
    var res = 0
    if ((request.status == 200) && (request.responseText))
      res = parseFloat(request.responseText)
    return res;
  }

  function setTrackName(name) {
    trackname = name
    document.title = WTRACKS + (name ? (" - " + trackname) : "")
    setElement("trktitle", trackname)
  }
  
  function getText(element) {
    return element.textContent ? element.textContent : element.text
  }

  function setText(element, text) {
    element.textContent = text;
    element.innerText = text
  }
  
  function setElement(elid, v) {
    document.getElementById(elid).innerHTML = v;
  }

  function addElement(elid, v) {
    document.getElementById(elid).innerHTML += v;
  }

  function DocElement(id) {
    this.id = id;
  }

  DocElement.prototype.set = function(html) {
    document.getElementById(this.id).innerHTML = html;
  }

  DocElement.prototype.add = function(html) {
    document.getElementById(this.id).innerHTML += html;
  }

  function wt_updateSpeedProfile() {
    var res = document.getElementById("speedprofile").selectedIndex
    if (res < 0) res = 0;
    speedProfile = speed_profiles[res];
    for (i = 0 ; i < trkpts.length; i++) {
      trkpts[i].Trkpt_updateTime()
    }
    if (isroundtrip) {
       for (i = trkpts.length - 1 ; i >= 0 ; i--) {
        trkpts[i].Trkpt_updateTime_rt()
      } 
    }
  }

  function showDistance(dist) {
    dist = Math.round(dist);
    if (dist > 10000) {
      return (dist/1000).toFixed(2) + " km";
    } else {
      return dist + " m";
    }
  }
    
  function showTime(time) {
    var strTime = "";
    if (time >= 3600) strTime += Math.floor(time/3600) + "h";
    time %= 3600; 
    if (time >= 60) strTime += Math.floor(time/60) + "m";
    time %= 60; 
    strTime += Math.round(time) + "s";
    return strTime
  }
    
  function showDateTime(time) {
    var strTime = "P";
    if (time >= 3600) strTime += Math.floor(time/3600) + "H";
    time %= 3600; 
    if (time >= 60) strTime += Math.floor(time/60) + "M";
    time %= 60; 
    strTime += Math.round(time) + "S";
    return strTime
  }
    
  function areMarkersShown() {
    return document.getElementById("showmarkers").checked;
  }
  
  function areWptsShown() {
    return document.getElementById("showwaypoints").checked;
  }
  
  function areLabelsShown() {
    return document.getElementById("showlabels").checked;
  }

  function slope(dist, altdiff) {
    return (altdiff / dist) * 100;
  }

  // Distance 3D = square(a^2 + b^2)
  function distance3D(trkpt1, trkpt2) {
    var a = trkpt2.getPoint().distanceFrom(trkpt1.getPoint());
    var b = trkpt2.wt_alt() - trkpt1.wt_alt();
    return Math.sqrt((a*a) + (b*b));
  }

  // Add '0' before values below 10  
  function lead0( v ) {
    if (v < 10) return "0" + v;
    return v;
  }

  /*------------ SpeedProfile -----------*/

  function SpeedProfile(name, sspairs) {
    this.name = name;
    this.sspairs = sspairs;
  }
  
  SpeedProfile.prototype.getDuration = function(dist, slope) {
    
    // regle de trois : m_pers_s / dist = 1 / res
    function distSpeed(dist, m_per_s) {
      return dist / m_per_s;
    }
    
    if (this.sspairs.length == 0) return 0
    if ((this.sspairs.length == 1)
      || (slope <= this.sspairs[0][0]))
       return distSpeed(dist, this.sspairs[0][1]); 
    if (slope >= this.sspairs[this.sspairs.length - 1][0])
       return distSpeed(dist, this.sspairs[this.sspairs.length - 1][1]); 
    var i = 1;
    while (i < this.sspairs.length) {
      if ((slope >= this.sspairs[i-1][0]) && (slope < this.sspairs[i][0])) {
        var diffslope = this.sspairs[i][0] - this.sspairs[i-1][0];
        var a = (this.sspairs[i][1] - this.sspairs[i-1][1])/diffslope ;
        var res = (a * (slope - this.sspairs[i-1][0])) + this.sspairs[i-1][1];
        return distSpeed(dist, res);
      }
      i++;
    }
    return 0;
  }  

  /*------------ Wpt --------------*/
  
  function toPt(marker, i) {
    marker.wt_manalt = undefined
    marker.wt_name = undefined
    marker.wt_label = undefined
    marker.wt_i = i
    // click event
    GEvent.addListener(marker, "click", function() {
      wt_showInfo(marker, true)
    });
    // drag event
    GEvent.addListener(marker, "dragend", function() {
      marker.wt_relocate(false)
    });
    // drag event
    GEvent.addListener(marker, "drag", function() {
      marker.wt_relocate(false)
    });

    // show marker
    marker.wt_showMarker(true);
  }
  
  GMarker.prototype.Wt_getName = function() {
    return (this.wt_name ? this.wt_name : "");
  }
  
  GMarker.prototype.Wpt_relocate = function(openinfo) {
    map.closeInfoWindow();
    if (this.wt_label) this.wt_label.setPoint(this.getPoint());
    if (openinfo) {
      this.wt_showInfo(true);
    }
  }
  

  GMarker.prototype.wt_infoHead = function() {
    var ptinfo = "Name: <input type='text' size='10' value='" + this.Wt_getName() 
        + "' onchange='"+ this.wt_arrayname + "[" + this.wt_i + "].wt_setName(this.value)' onkeyup='"
        + this.wt_arrayname + "[" + this.wt_i + "].wt_setName(this.value)'/><br/>";
    ptinfo += "Position: <span id='ppos'>" + this.getPoint().toUrlValue() + "</span><br/>";
    return ptinfo
  }
  
  GMarker.prototype.Wpt_showInfo = function(openinfo) {
     current_trkpt = undefined
     info.set("");
     if (openinfo) {
       var ptinfo = "<form style='font-size:smaller'>";

       ptinfo += this.wt_infoHead()
       ptinfo += "Altitude: <span id='altv'>" + this.wt_altview() + "</span>";
       ptinfo += " <a href='javascript:wpts[" + this.wt_i + "].Wpt_setAltDB()'>alt DB</a>";
       ptinfo += "</form>";
       ptinfo += "<a href='javascript:wpts[" + this.wt_i + "].Wpt_delete()'>Delete</a> - ";
       ptinfo += "<a href='javascript:wpts[" + this.wt_i + "].Wpt_duplicate()'>Duplicate</a>";
       
       map.openInfoWindowHtml(this.getPoint(), ptinfo);
    }
  }
  
  GMarker.prototype.Wpt_altview = function() {
    var scripttxt = this.wt_arrayname + "[" + this.wt_i + "].wt_setAlt(false, this.value); wt_showInfo(" 
                    + this.wt_arrayname + "[" + this.wt_i + "],false)" 
    var alt = this.wt_alt()
    if (alt == undefined) alt = ""
    return "<input type='text' size='4' name='alt' value='" + alt + "' onchange='" + scripttxt + "' onkeyup='" + scripttxt + "'/>";
  }

  GMarker.prototype.wt_updateTitle = function() {
    var title = "";
    if (this.wt_name && this.wt_name != "") title += this.wt_name;
    if ((this.wt_manalt != undefined) && (this.wt_autoalt == undefined || !this.wt_autoalt)) {
      title += " (" + this.wt_manalt + "&nbsp;m)";
    }
    if (title != "") {
      if (this.wt_label) {
        this.wt_label.setContents(title);
      } else {
        this.wt_label = new ELabel(this.getPoint(), title, "ptlabel", new GSize(0,10), 70);
        if (this.wt_areLabelsShown()) {
          clusterer.AddMarker(this.wt_label, this.wt_label.html);
        }
      }
    } else {
      if (this.wt_label) {
        clusterer.RemoveMarker(this.wt_label);
        this.wt_label = undefined;
      }
    }
  }

  GMarker.prototype.wt_setName = function(name) {
    this.wt_name = name;
    this.wt_updateTitle();
  }

  GMarker.prototype.Wpt_setAlt = function(auto, man) {
    this.wt_manalt = man ? parseFloat(man) : undefined;
    this.wt_autoalt = auto;
    this.wt_updateTitle();
  }

  GMarker.prototype.Wpt_setAltDB = function() {
    this.wt_setAlt(false, getAltitude( this.getPoint().lat(), this.getPoint().lng() ));
    wt_showInfo(this, true)
  }

  GMarker.prototype.wt_updateAutoalt = function(newautoalt) {
    //debug.set("i=" + i + ", newautoalt=" + newautoalt);
    this.wt_setAlt(newautoalt, this.wt_alt());
    wt_showInfo(this, false)
    var altv = document.getElementById("altv");
    altv.innerHTML = this.wt_altview();
  }

  GMarker.prototype.wt_showMarker = function(isnew) {
    if (this.wt_areMarkersShown()) {
      // show marker
      clusterer.AddMarker(this, this.Wt_getName())
    } else if (!isnew) {
      clusterer.RemoveMarker(this)
    }
  }
  
  GMarker.prototype.Wpt_alt = function() {
    return this.wt_manalt
  }
  
  GMarker.prototype.Wpt_duplicate = function() {
    var pos = new GLatLng(this.getPoint().lat()+0.0001, this.getPoint().lng()+0.0001)
    var pt = new_Wpt(pos)
    pt.wt_manalt = this.wt_manalt
    pt.wt_setName(this.wt_name)
    wt_showInfo(this, true)
    map.openInfoWindowHtml(pos, "Duplicated point");
  }
  
  GMarker.prototype.Wpt_delete = function() {
    map.closeInfoWindow();
    var newwpts = [];

    for (i=0; i < wpts.length; i++) {
     if (i != this.wt_i){
       wpts[i].wt_i = newwpts.length 
       newwpts.push(wpts[i])
     }
    }
    clusterer.RemoveMarker(this);
    if (this.wt_label) clusterer.RemoveMarker(this.wt_label)
    wpts = newwpts
  }

  GMarker.prototype.toWpt = function(i) {
    this.dummy = "dummy"
    this.wt_arrayname = "wpts"
    this.wt_gpxelt = "wpt"
    this.wt_relocate = GMarker.prototype.Wpt_relocate
    this.wt_showInfo = GMarker.prototype.Wpt_showInfo
    this.wt_alt = GMarker.prototype.Wpt_alt
    this.wt_altview = GMarker.prototype.Wpt_altview
    this.wt_areMarkersShown = areWptsShown
    this.wt_areLabelsShown = areWptsShown
    this.wt_setAlt = GMarker.prototype.Wpt_setAlt

    toPt(this, i)
    this.wt_updateTitle();
  }
    
  GMarker.prototype.wt_toGPX = function(savealt, savetime) {
    var gpx = "<" + this.wt_gpxelt + " ";
    gpx += "lat=\"" + this.getPoint().lat() + "\" lon=\"" + this.getPoint().lng() + "\">";
    if (this.wt_name) {
      gpx += "<name>" + this.wt_name + "</name>";
    }
    if ((savealt && (this.wt_manalt != undefined)) || 
    ((this.wt_manalt != undefined) && (this.wt_autoalt == undefined || !this.wt_autoalt))
    ) {
      gpx += "<ele>" + this.wt_manalt + "</ele>";
    }
    if (savetime && (this.wt_mantime != undefined)) {
      gpx += "<time>" + showDateTime(this.wt_mantime) + "</time>";
    }
    gpx += "</" + this.wt_gpxelt + ">\n";
    return gpx;
  }
    

  function new_Wpt(point, alt, name) {
    var pt = new GMarker(point, {draggable: true, icon: wp_icon}) //  (icon setting doesn't work)
    pt.toWpt(wpts.length)
    wpts.push(pt)
    if (alt) pt.wt_setAlt(false, alt)
    if (name) pt.wt_setName(name)
    return pt
  }
  

 /*------------- Trkpt ------------*/
 
  GMarker.prototype.Trkpt_altview = function() {
    if (this.wt_autoalt) {
      return this.wt_alt();
    } else {
      return this.Wpt_altview();
    }      
  }

  GMarker.prototype.Trkpt_setAlt = function(auto, man) {
    this.Wpt_setAlt(auto, man)
    // update infos from last known alt point
    var i = this.wt_i > 0 ? this.wt_i-1 : 0 
    while ((i > 0) && (trkpts[i].wt_autoalt)) {
      i--
    }
    wt_updateInfoFrom(trkpts[i])
  }

  GMarker.prototype.Trkpt_relocate = function(openinfo) {
    map.closeInfoWindow();
    points[this.wt_i] = this.getPoint();
    wt_drawPolyline();
    if (this.wt_label) this.wt_label.setPoint(this.getPoint());
    wt_updateInfoFrom(this)
    if (openinfo) {
      wt_showInfo(this, true);
    } else {
      wt_showInfo(undefined, false);
    }
  }
  
  GMarker.prototype.Trkpt_updateAlt = function() {
    // --- altitude
    if (this.wt_autoalt) {
      if ((this.wt_i > 0) && ((this.wt_i + 1) < trkpts.length)) {
        var previ = this.wt_i-1;
        var prevdist = trkpts[previ].getPoint().distanceFrom(this.getPoint());
        while ((previ > 0) && trkpts[previ].wt_autoalt) {
          previ--;
          prevdist += trkpts[previ].getPoint().distanceFrom(
                        trkpts[previ+1].getPoint()); 
        }
        var nexti = this.wt_i+1;
        var nextdist = trkpts[nexti].getPoint().distanceFrom(this.getPoint());
        while ((nexti < (trkpts.length - 1)) && trkpts[nexti].wt_autoalt) {
          nexti++;
          nextdist += trkpts[nexti].getPoint().distanceFrom(
                       trkpts[nexti-1].getPoint()); 
        }
        this.wt_manalt = 
          trkpts[previ].wt_alt() + Math.round(
             (   trkpts[nexti].wt_alt()
               - trkpts[previ].wt_alt() ) 
              * (prevdist / (prevdist + nextdist)));
      } else {
        this.wt_manalt = 0
      }
    }
  }
  
  // --- distance
  GMarker.prototype.Trkpt_updateDistance = function() {
    if (this.wt_i > 0) {
      var prev = trkpts[this.wt_i-1]
      var prevalt = prev.wt_alt()
      var alt = this.wt_alt()
      this.wt_rdist = distance3D(prev, this);
      this.wt_tdist = prev.wt_tdist + this.wt_rdist;
    } else {
      this.wt_rdist = 0
      this.wt_tdist = 0
    }
  }
    
  // -- time
  GMarker.prototype.Trkpt_updateTime = function() {
    if (this.wt_autotime) {
      if (this.wt_i > 0) {
        var dist = distance3D(trkpts[this.wt_i-1], trkpts[this.wt_i]);
        var diffalt = this.wt_alt() - trkpts[this.wt_i-1].wt_alt();
        var slopev = slope(dist, diffalt);
        this.wt_mantime = trkpts[this.wt_i-1].wt_time()
                          + speedProfile.getDuration(dist, slopev);
      } else {
        this.wt_mantime = 0;
      }
    }
  }

  GMarker.prototype.Trkpt_updateTime_rt = function() {
    if (this.wt_autotime) {
      if (this.wt_i < trkpts.length - 1) {
        var dist = distance3D(trkpts[this.wt_i+1], trkpts[this.wt_i]);
        var diffalt = this.wt_alt() - trkpts[this.wt_i+1].wt_alt();
        var slopev = slope(dist, diffalt);
        this.wt_mantime_rt = trkpts[this.wt_i+1].wt_time_rt()
                             + speedProfile.getDuration(dist, slopev);
      } else {
        this.wt_mantime_rt = this.wt_mantime;
      }
    }
  }

  GMarker.prototype.Trkpt_showInfo = function(openinfo) {
     current_trkpt = this
     if (openinfo) {

       var ptinfo = "<form style='font-size:smaller'>";
       ptinfo += this.wt_infoHead()
       ptinfo += "Altitude: Auto? <input type='checkbox' id='autoalt'" 
            +  (this.wt_autoalt ? " checked" : "") 
            + " onclick='trkpts[" + this.wt_i + "].wt_updateAutoalt(autoalt.checked)'/>"
            + "<span id='altv'>" + this.wt_altview() + "</span>"
       ptinfo += " <a href='javascript:trkpts[" + this.wt_i + "].Wpt_setAltDB()'>alt DB</a><br/>"
       ptinfo += "Time: <span id='ptime'>" + showTime(this.wt_time()) + "</span>"
       if (isroundtrip && (this.wt_time_rt() != this.wt_time())) {
         ptinfo += " and <span id='ptime_rt'>" + showTime(this.wt_time_rt()) + "</span>"
       }
       ptinfo += "</form>"; 
       ptinfo += "Distance from start: <span id='pdistt'>" + showDistance(this.wt_tdist) + "</span>";
       if (this.wt_i > 0) {
         ptinfo += "(<span id='pdistr'>" + showDistance(this.wt_rdist) + "</span> from last)";
       }
       ptinfo += "<br/>";
       if (this.wt_i > 0) {
         ptinfo += "<a href='javascript:trkpts[0].Trkpt_showInfo(true)'>|&lt</a>&nbsp;";
         ptinfo += "<a href='javascript:trkpts[" + (this.wt_i-1) + "].Trkpt_showInfo(true)'>&lt&lt</a>&nbsp;";
       }
       ptinfo += "<a href='javascript:trkpts[" + this.wt_i + "].Trkpt_delete()'>Delete</a> - ";
       ptinfo += "<a href='javascript:trkpts[" + this.wt_i + "].Trkpt_duplicate()'>Duplicate</a> - ";
       ptinfo += "<a href='javascript:trkpts[" + this.wt_i + "].Trkpt_detach()'>Detach</a>";
       if (this.wt_i < trkpts.length -1) {
         ptinfo += "&nbsp;<a href='javascript:trkpts[" + (this.wt_i+1) + "].Trkpt_showInfo(true)'>&gt;&gt;</a>";
         ptinfo += "&nbsp;<a href='javascript:trkpts[" + (trkpts.length-1) + "].Trkpt_showInfo(true)'>&gt;|</a>";
       }
       
       map.openInfoWindowHtml(this.getPoint(), ptinfo);
    } else {
      document.getElementById("pdistt").innerHTML = showDistance(this.wt_tdist)
      document.getElementById("pdistr").innerHTML = showDistance(this.wt_rdist)
      document.getElementById("ptime").innerHTML = showTime(this.wt_time())
      if (isroundtrip && (this.wt_time_rt() != this.wt_time())) {
        document.getElementById("ptime_rt").innerHTML = showTime(this.wt_time_rt())
      }
    }
  }

    
  GMarker.prototype.Trkpt_detach = function() {
    var pt = new_Wpt(this.getPoint(), this.wt_manalt, this.wt_name)
    this.Trkpt_delete()
    wt_showInfo(undefined, false)
    pt.wt_showInfo(true)
  }
  
  GMarker.prototype.Trkpt_duplicate = function() {
    map.closeInfoWindow();
    var newpoints = [];
    var newtrkpts = [];
    var pt
    var pos
    for (i=0; i < trkpts.length; i++) {
     trkpts[i].wt_i = newtrkpts.length
     newtrkpts.push(trkpts[i])
     newpoints.push(trkpts[i].getPoint())
     if (i == this.wt_i){
       pos = new GLatLng(trkpts[i].getPoint().lat()+0.0001, trkpts[i].getPoint().lng()+0.0001)
       pt = new GMarker(pos, {draggable: true, icon: trkpt_icon})
       pt.toTrkpt(newtrkpts.length)
       pt.wt_i = newtrkpts.length
       newtrkpts.push(pt)
       newpoints.push(pos)
       map.openInfoWindowHtml(pos, "Duplicated point");
     }
    }
    points = newpoints;
    trkpts = newtrkpts
    wt_updateInfoFrom(pt)
    wt_drawPolyline();
  }
  
  GMarker.prototype.Trkpt_delete = function() {
    map.closeInfoWindow();
    var newpoints = [];
    var newtrkpts = [];
    for (i=0; i < trkpts.length; i++) {
     if (i != this.wt_i){
       trkpts[i].wt_i = newtrkpts.length
       newtrkpts.push(trkpts[i])
       newpoints.push(trkpts[i].getPoint())
     }
    }
    clusterer.RemoveMarker(this);
    if (this.wt_label) clusterer.RemoveMarker(this.wt_label)
    points = newpoints;
    trkpts = newtrkpts
    wt_drawPolyline();
    if (this.wt_i > 0) {
      wt_updateInfoFrom(trkpts[this.wt_i - 1])
    }
    wt_showInfo(undefined, false)
  }

  
  GMarker.prototype.Trkpt_alt = function() {
    return this.wt_manalt ? this.wt_manalt : 0
  }
   
  GMarker.prototype.wt_time = function() {
    return this.wt_mantime;
  }

  GMarker.prototype.wt_time_rt = function() {
    return this.wt_mantime_rt;
  }

  GMarker.prototype.toTrkpt = function(i) {
    this.wt_arrayname = "trkpts"
    this.wt_gpxelt = "trkpt"
    this.wt_relocate = GMarker.prototype.Trkpt_relocate
    this.wt_showInfo = GMarker.prototype.Trkpt_showInfo
    this.wt_alt = GMarker.prototype.Trkpt_alt
    this.wt_altview = GMarker.prototype.Trkpt_altview
    this.wt_areMarkersShown = areMarkersShown
    this.wt_areLabelsShown = areLabelsShown
    this.wt_setAlt = GMarker.prototype.Trkpt_setAlt
    this.wt_autoalt = true;
    this.wt_autotime = true; // not used yet...
    this.wt_mantime = 0
    this.wt_mantime_rt = 0
    // computed data cache
    this.wt_rdist = 0
    this.wt_tdist = 0
    
    toPt(this, i)
  }

  function new_Trkpt(point, alt, name) {
    var pt = new GMarker(point, {draggable: true, icon: trkpt_icon })
    pt.toTrkpt(trkpts.length, alt, name)
    trkpts.push(pt)
    points.push(pt.getPoint())
    if (name) pt.wt_setName(name)
    if (alt) {
      pt.wt_setAlt(false, alt)
    } else {
      wt_updateInfoFrom(pt)
    } 
    return pt
  }

  /*------------ Global functions -----------*/

  function wt_updateAltBounds(pt) {
    var alt = pt.wt_alt()
    if (pt.wt_i > 0) {
      minalt = Math.min(minalt, alt);
      maxalt = Math.max(maxalt, alt);
      var prevalt = trkpts[pt.wt_i-1].wt_alt()
      if (alt > prevalt) {
        climbing += alt - prevalt;
      } else {
        descent += prevalt - alt;
      }
    } else {    
      minalt = alt;
      maxalt = alt;
      climbing = 0
      descent = 0
    }
  }

  function wt_updateInfoFrom(pt) 
  {
    i = 0;
    while (i < pt.wt_i) {
      wt_updateAltBounds(trkpts[i++])
    }
    do {
      pt = trkpts[i]
      pt.Trkpt_updateAlt()
      pt.Trkpt_updateDistance()
      pt.Trkpt_updateTime()
      wt_updateAltBounds(trkpts[i++])
    } while (i < trkpts.length)
    if (isroundtrip) {
       for (i = trkpts.length - 1 ; i >= 0 ; i--) {
        trkpts[i].Trkpt_updateTime_rt()
      }
    }
  }
  
  function wt_showInfo(marker, openinfo) {
    info.set("");
    
    var duration = 0
    var duration_rt = 0
    // Last point's time
    if (trkpts.length > 1) {
      duration = trkpts[trkpts.length-1].wt_time() - trkpts[0].wt_time()
      duration_rt = trkpts[0].wt_time_rt() - trkpts[0].wt_time()
    }
    var tdist = 0
    if (trkpts.length > 0) {
      tdist = trkpts[trkpts.length-1].wt_tdist
    }
    
    setElement("distow", showDistance(tdist));
    setElement("distrt", showDistance(2*tdist));
    setElement("timeow", showTime(duration));
    setElement("timert", showTime(duration_rt));
    setElement("altmin", Math.round(minalt));
    setElement("altmax", Math.round(maxalt));
    setElement("climbing", Math.round(climbing));
    setElement("descent", Math.round(descent));

    if (marker) marker.wt_showInfo(openinfo)
    
  }

    
  function wt_toGPX(savealt, savetime) {
    var gpx = '<\?xml version="1.0" encoding="ISO-8859-1" standalone="no" \?>\n';
    gpx += '<gpx creator="WTracks" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.topografix.com/GPX/1/1" version="1.1" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">\n';
    gpx += "<metadata>\n"
    gpx += "  <name>" + trackname + "</name>\n"
    gpx += "  <desc></desc>\n"
    gpx += "  <author><name>" + WTRACKS + "</name></author>\n"
    gpx += '  <link href="http://<?=$host?>">\n'
    gpx += "    <text>WTracks</text>\n"
    gpx += "    <type>text/html</type>\n"
    gpx += "  </link>\n"
    var t = new Date();
    t = new Date(Date.UTC(1900 + t.getYear(), t.getMonth(), t.getDate(),
                          t.getHours(), t.getMinutes(), t.getSeconds()));
    var strtime = (1900 + t.getYear()) + "-" + lead0(1+t.getMonth()) + "-" + lead0(t.getDate()) + "T" 
                  + lead0(t.getHours()) + "-" + lead0(t.getMinutes()) + "-" + lead0(t.getSeconds()) + "Z";
    gpx += "  <time>" + strtime + "</time>\n"
    var sw = map.getBounds().getSouthWest();
    var ne = map.getBounds().getNorthEast();
    gpx += '<bounds minlat="' + Math.min( sw.lat(), ne.lat()) + '" minlon="' + Math.min( sw.lng(), ne.lng()) + '" maxlat="' + Math.max( sw.lat(), ne.lat()) + '" maxlon="'+ Math.max( sw.lng(), ne.lng()) + '"/>';
    gpx += "</metadata>\n"
 
    var i = 0;
    while (i < wpts.length) {
      gpx += "  " + wpts[i].wt_toGPX(savealt, savetime);
      i++;
    }
    gpx += "<trk><name>the track</name><trkseg>\n";
    i = 0;
    while (i < trkpts.length) {
      gpx += "  " + trkpts[i].wt_toGPX(savealt, savetime);
      i++;
    }
    gpx += "</trkseg></trk></gpx>\n";
    return gpx;
  }
      

  function wt_drawPolyline() {
    if (polyline) {
      map.removeOverlay(polyline);
    }
    if (points && points.length > 0) {
      polyline = new GPolyline(points, "#ff0000", 5);
      map.addOverlay(polyline);
    } else {
      polyline = undefined
    }
  }

  function wt_clear() {
    map.clearOverlays()
    var i = 0
    while (i < trkpts.length) {
      clusterer.RemoveMarker(trkpts[i])
      if (trkpts[i].wt_label) clusterer.RemoveMarker(trkpts[i].wt_label)
      i++
    }
    i = 0
    while (i < wpts.length) {
      clusterer.RemoveMarker(wpts[i])
      if (wpts[i].wt_label) clusterer.RemoveMarker(wpts[i].wt_label)
      i++
    }
    polyline = undefined
    points = [];
    trkpts = [];
    wpts = [];
    current_trkpt = undefined
    minalt = 0
    maxalt = 0

    descent = 0
    climbing = 0
    setTrackName("New Track")
  }
  

  function wt_loadGPX(filename) {
    close_popup('load-box');
    //info.set("loading " + filename + "...<br>");
    info.set("<img src='img/processing.gif'> Loading...");
    GDownloadUrl("httpget_proxy.php?" + filename, function(data, responseCode) {
      wt_importGPX(data);
    });
  }

  function wt_importPoints(xmlpts, is_trk) {
    var point;
    for (var i = 0; i < xmlpts.length; i++) {
      point = new GLatLng(parseFloat(xmlpts[i].getAttribute("lat")),
                          parseFloat(xmlpts[i].getAttribute("lon")));
      var ele = undefined
      var eles = xmlpts[i].getElementsByTagName("ele");
      if (eles.length > 0) {
        ele  = parseFloat(getText(eles[0]))
      }
      var name = undefined
      var names = xmlpts[i].getElementsByTagName("name");
      if (names.length > 0) {
        name  = getText(names[0])
      }
      if (is_trk) {
        pt = new_Trkpt(point, ele, name)
      } else {
        pt = new_Wpt(point, ele, name)
      } 
    }

  }
    
  function wt_importGPX(gpxinput) {
      wt_clear();
      if (!gpxinput || gpxinput == "") {
        info.add("Failed to read file<br>")
        return
      }
      info.add("Importing... <br>");
      var xml = GXml.parse(gpxinput);
      var gpx = xml ? xml.getElementsByTagName("gpx") : undefined 
      //debug.set("gpxinput:<textarea width='40' height='20'>" + gpxinput + "</textarea>")
      debug.add("xml:" + xml)
      if (!xml.documentElement || !gpx || (gpx.length == 0)) {
        info.add("The file is not in gpx format<br>")
        return
      }
      gpx = xml.documentElement
      if (xml) {
        var metadata = gpx.getElementsByTagName("metadata");
        if (metadata && metadata.length > 0) {
          metadata = metadata[0].getElementsByTagName("name");
          if (metadata && metadata.length > 0) {
            setTrackName(getText(metadata[0]))
          }
        }
        var bounds = gpx.getElementsByTagName("bounds");
        var pts = gpx.getElementsByTagName("trkpt");
        if (pts) wt_importPoints(pts, true);
        pts = gpx.getElementsByTagName("wpt");
        if (pts) wt_importPoints(pts, false);
        var center = new GLatLng(0,0)
        var zoom = 10
        var mapbounds = new GLatLngBounds();
        if (bounds && bounds.length > 0) {
          //debug.add(bounds.length)
          var sw = new GLatLng(parseFloat(bounds[0].getAttribute("minlat")),
                               parseFloat(bounds[0].getAttribute("minlon")))
          var ne = new GLatLng(parseFloat(bounds[0].getAttribute("maxlat")),
                               parseFloat(bounds[0].getAttribute("maxlon")))
          mapbounds = new GLatLngBounds(sw, ne)
        } else {
          // compute bounds to include all trackpoints and waypoints
          if (trkpts) {
            for(var i = 0; i < trkpts.length; i++) { 
              mapbounds.extend(trkpts[i].getPoint());
            } 
          }
          if (wpts) {
            for(var i = 0; i < wpts.length; i++) { 
              mapbounds.extend(wpts[i].getPoint());
            } 
          }
        }
        center = mapbounds.getCenter()
        //zoom = Math.max(map.getBoundsZoomLevel(mapbounds),15)      
        zoom = map.getBoundsZoomLevel(mapbounds)   
        map.setCenter(center, zoom);
        if (trkpts && trkpts.length > 0) {
          var pt = trkpts[trkpts.length - 1];
          wt_drawPolyline();
          wt_showInfo(pt, true);
        }
        info.set("");
      } else {
        info.set("Can't read GPX input file");
      }
  }
  
  function wt_showTrkMarkers(show) {
    //map.closeInfoWindow();
    var i = 0;
    while (i < trkpts.length) {
      if (show) {
        clusterer.AddMarker(trkpts[i], trkpts[i].Wt_getName());
      } else {
        clusterer.RemoveMarker(trkpts[i]);
      }
      i++;
    }
  }
  
  function wt_showLabels(show) {
   //map.closeInfoWindow();
    var i = 0;
    while (i < trkpts.length) {
      if (trkpts[i].wt_label) {
        if (show) {
          trkpts[i].wt_label.show();
        } else {
          trkpts[i].wt_label.hide();
        }
      }
      i++;
    }
  }
  
  function wt_showWaypoints(show) {
    //map.closeInfoWindow();
    var i = 0;
    while (i < wpts.length) {
      if (show) {
        clusterer.AddMarker(wpts[i], wpts[i].Wt_getName());
      } else {
        clusterer.RemoveMarker(wpts[i]);
      }
      if (wpts[i].wt_label) {
        if (show) {
          clusterer.AddMarker(wpts[i].wt_label, wpts[i].wt_label.html);
        } else {
          clusterer.RemoveMarker(wpts[i].wt_label);
        }
      }
      i++;
    }
  }
  
  function wt_showAddress(address) {
    geocoder.getLatLng(
      address,
      function(point) {
        if (!point) {
          alert(address + " not found");
        } else {
          map.setCenter(point, 13);
          map.openInfoWindowHtml(point, address);
        }
      }
    );
  }

  //----- Stop page scrolling if wheel over map ----
  function wheelevent(e)
  {
    if (!e) { e = window.event; }
    if (e.preventDefault) { e.preventDefault(); }
    if (e.preventBubble) { e.preventBubble(); }
    e.returnValue = false;
  }
  
  function wt_load() {
    if (GBrowserIsCompatible()) {
      info = new DocElement("message");
      debug = new DocElement("debug");

      var mapDiv = document.getElementById("map")
      map = new GMap2(mapDiv);
      map.addControl(new GLargeMapControl());
      map.addControl(new GMapTypeControl());
      map.addControl(new GOverviewMapControl());
      map.setCenter(new GLatLng(0,0), 3, G_HYBRID_MAP);
      map.enableScrollWheelZoom();
      
      //----- Stop page scrolling if wheel over map ----
      GEvent.addDomListener(mapDiv, "DOMMouseScroll", wheelevent);
      mapDiv.onmousewheel = wheelevent;
      
      // to allow many points without perf issue
      // see http://www.acme.com/javascript/#Clusterer
      clusterer = new Clusterer(map);

      geocoder = new GClientGeocoder();
      
      // speed profiles = pairs of <slope, meters per second>

      speed_profiles.push(new SpeedProfile("Walking",
      [ [-35, 0.4722], [-25, 0.555], [-20, 0.6944], [-14, 0.8333], [-12, 0.9722],
        [-10, 1.1111], [-8, 1.1944], [-6, 1.25], [-5, 1.2638], [-3, 1.25], 
        [2, 1.1111], [6, 0.9722], [10, 0.8333], [15, 0.6944], [19, 0.5555],
        [26, 0.4166], [38, 0.2777] ] ))
      
      speed_profiles.push(new SpeedProfile("Running",
      [ [-16, (12.4/3.6)], [-14,(12.8/3.6)], [-11,(13.4/3.6)], [-8,(12.8/3.6)],
        [-5,(12.4/3.6)], [0,(11.8/3.6)], [9,(9/3.6)], [15,(7.8/3.6)] ] ))
      
      speed_profiles.push(new SpeedProfile("Cycling",
      [ [-6, 13.8888], [-4, 11.1111], [-2, 8.8888], [0, 7.5], [2, 6.1111],
        [4, (16/3.6)], [6, (11/3.6)] ] ))
      
      speed_profiles.push(new SpeedProfile("VTT (cross country cycling)", [ [0, 3.33] ]));

      speed_profiles.push(new SpeedProfile("Swimming", [ [0, 0.77] ]));

      var sp = document.getElementById("speedprofile");
      sp.style.textAlign = "right";
      var i = 0
      var res = ""
      while (i < speed_profiles.length) {
        var opt = document.createElement("option");
        setText(opt, speed_profiles[i].name)
        opt.style.textAlign = "right";
        sp.appendChild(opt);
        //res += "<option value='" + speed_profiles[i].name + "'>" + speed_profiles[i].name + "</option> "
        i++
      }
      wt_updateSpeedProfile()

      // click event
      GEvent.addListener(map, "click", function(marker, point) {
        if (!marker) {
          var pt = new_Trkpt(point);
          wt_drawPolyline();
          wt_showInfo(undefined, false);
        }
      });
      
<?php
  if ($file<>'') {
      echo "info.set('Uploaded ".$file_name."<br>')\n";
?>
      wt_importGPX(document.getElementById('gpxarea').value);
<?php
    } else {
?>

      var gpxurl="<?= $_REQUEST["gpx"] ?>";
      if (gpxurl.length>1) {
debug.add(gpxurl);
        //document.getElementById("showmarkers").checked = false;     
      } else {

        gpxurl = "tracks/everest.gpx";
      }
      wt_loadGPX(gpxurl);
<?php
    }
?>
    }
  }

  function wt_check_fileupload(form) {
    if (form.gpxfile.value == '') {
      alert ("Please enter the file name to upload");
      form.gpxfile.focus ();
      return false;
    }
    close_popup('load-box');
    form.marks.value = document.getElementById('showmarkers').checked;
    form.labels.value = document.getElementById('showlabels').checked;
    return true;
  }

  function wt_update_infos() {
    if (map.getInfoWindow().isHidden()) {
      current_trkpt = undefined
    }
    wt_showInfo(current_trkpt, current_trkpt != undefined);
  }
  
  function wt_clear_trackinfo() {
    setElement("distow", "");
    setElement("distrt", "");
    setElement("timeow", "");
    setElement("timert", "");
    setElement("altmin", "");
    setElement("altmax", "");
    setElement("climbing", "");
    setElement("descent", "");
  }

  /* ------------ option pop up taken from http://www.marengo-ltd.com/map/ */
  
  function addMapHeight(v) {
    mapdiv = document.getElementById("map")
    maph = mapdiv.style.height
    maphv = maph.substr(0,maph.indexOf("px"))
    maphv = parseInt(maphv)
    maphv += v
    mapdiv.style.height = maphv + "px"
  }

  function check_for_escape(e, sPopupID){
    //debug.add(String.fromCharCode(e.keyCode))
    if (e.keyCode==27) {
      close_popup(sPopupID);
    }
  }

  function close_popup(sID) {
    if(document.layers) //NN4+
    {
       document.layers[sID].visibility = "hide";
    }
    else if(document.getElementById) //gecko(NN6) + IE 5+
    {
        var obj = document.getElementById(sID);
        obj.style.visibility = "hidden";
    }
    else if(document.all) // IE 4
    {
        document.all[sID].style.visibility = "hidden";
    }
  }

  function show_popup(sID) {
    if(document.layers) //NN4+
    {
       document.layers[sID].visibility = "show";
    }
    else if(document.getElementById)  //gecko(NN6) + IE 5+
    {
        var obj = document.getElementById(sID);
        obj.style.visibility = "visible";
    }
    else if(document.all) // IE 4
    {
        document.all[sID].style.visibility = "visible";
    }
  }
  
  function show_save_box(){
    document.getElementById("trackname").value = trackname 
    close_popup("load-box");
    show_popup("save-box");
    var obj = document.getElementById("trackname");
    obj.focus();
  }
  
  function wt_doSave() {
    close_popup('save-box')
    trackname = document.getElementById("trackname").value
    document.getElementById("savedname").value = trackname;
    var savealt = document.getElementById("savealt").checked
    var savetime = document.getElementById("savetime").checked
    document.getElementById("gpxarea").value = wt_toGPX(savealt, savetime)
  }

  function show_user_tracks(res) {
    // set the whole div to bypass IE bug on dynamic selects
    document.getElementById("usertracks-span").innerHTML = 
          "<select name='url' id='usertracks'>" + res + "</select>\n";
    document.getElementById("deleteusertrack").disabled = false;
    document.getElementById("loadusertrack").disabled = false;
    document.getElementById("usertracks").disabled = false;
  }

  function load_tracks(params) {
    document.getElementById("deleteusertrack").disabled = true;
    document.getElementById("loadusertrack").disabled = true;
    document.getElementById("usertracks").disabled = true;
    Lokris.AjaxCall("usertracks.php" + params, show_user_tracks,
              { method: "POST", postBody: "oid=<?=$oid?>" });
  }

  function delete_track(url) {
    if (confirm("Delete this track?")) {
      load_tracks('&delete=' + url);
    }
  }

  function show_load_box(){
<?php
    if ($oid != "") {
?>
      load_tracks("");
<?php
   }
?>
    close_popup("save-box");
    show_popup("load-box");
    var obj = document.getElementById("gpxurl");
    obj.focus();
  }
  
  function clear_track() {
    wt_clear(); 
    wt_clear_trackinfo();
    info.set('');
  }

  function wt_doGraph() {
    if (trkpts.length == 0) {
      alert("No track defined yet. Click on the map!")
      return
    }
    if (minalt == maxalt) {
      alert("Track is flat! Nothing to display.")
      return
    }

    // build dataset
    var km = trkpts[trkpts.length-1].wt_tdist > 5000
    var i = 0;
    var ds = []
    while (i < trkpts.length) {
      var dspt = []
      var dist = Math.round(trkpts[i].wt_tdist)
      if (km) { 
        dist /= 1000
      }
      dspt.push(dist)
      dspt.push(trkpts[i].wt_alt())
      ds.push(dspt)
      i++;
    }
    //debug.add(repr(ds))

    // display
    var ymin = minalt < 0 ? minalt * 1.1 : minalt * 0.9
    var ymax = maxalt < 0 ? maxalt * 0.9 : maxalt * 1.1
    var altLimits = [ Math.round(ymin), Math.round(ymax) ]
    var layout = new PlotKit.Layout("line", {xOriginIsZero: false, yOriginIsZero: false, yAxis: altLimits});
    layout.addDataset("profile", ds);
    layout.evaluate();
       
    //var chart = new SweetCanvasRenderer(document.getElementById("graph"), layout);
    var chart = new PlotKit.SweetCanvasRenderer($("graph"), layout);
    chart.render();
    show_popup("graph-box")
  }

    //]]>
    </script>

<!-- plotkit includes (for graph disply) -->
   <script src="MochiKit.js" type="text/javascript"></script>
   <script src="excanvas.js" type="text/javascript"></script>
   <script src="PlotKit_Packed.js" type="text/javascript"></script>
<!-- end of plotkit includes -->

<!-- utility scripts -->
   <script src="gpsies_clusterer2.js" type="text/javascript"></script>
   <script src="http://www.ajaxbuch.de/lokris/lokris.js" type="text/javascript"></script>
   <script src="elabel.js" type="text/javascript"></script>

  <!-- RPXNOW -->
<script src="https://rpxnow.com/openid/v2/widget"
        type="text/javascript"></script>
<script type="text/javascript">
  RPXNOW.token_url = "http://<?php echo $host.$rpxnow_token_url?>";
  RPXNOW.realm = "<?= file_get_contents('private/rpxnow.realm')?>";
  RPXNOW.overlay = true;
  RPXNOW.language_preference = 'en';
</script>
  <!-- END OF RPXNOW -->

</html>

