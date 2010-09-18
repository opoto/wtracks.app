<!-- file upload imports -->
<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.servlet.ServletFileUpload, org.apache.commons.fileupload.disk.DiskFileItemFactory, java.util.*, java.io.*, java.lang.Exception" %>
<%
  String host = request.getServerName();
  String rpxgoto = "goto=" + java.net.URLEncoder.encode(request.getRequestURI());
  String rpxnow_token_url = "/login.jsp?" + rpxgoto;
  boolean debugging = (request.getParameter("debug") != null);

  String file = ""; // $HTTP_POST_FILES['gpxfile']['tmp_name'];
  String file_name = ""; // $HTTP_POST_FILES['gpxfile']['name'];

  boolean showmarkers = !("false".equals(request.getParameter("marks")));
  boolean showlabels = !("false".equals(request.getParameter("labels")));

  String openID = null;

  // following config file should define gmaps_key, ganalytics_key, and rpxnow_realm
%>
<%@ include file="config.jsp" %>
<%@ include file="userid.jsp" %>

<%
  // File Upload detection
  if (ServletFileUpload.isMultipartContent(request)){
    ServletFileUpload servletFileUpload = new ServletFileUpload(new DiskFileItemFactory());
    FileItemIterator it = servletFileUpload.getItemIterator(request);

    String optionalFileName = "";
    FileItemStream fileItem = null;

    try {
      while (it.hasNext()){
          fileItem = (FileItemStream)it.next();
          if (!fileItem.isFormField()) {
            file_name = fileItem.getName();
            System.out.println("reading file: " + file_name);
            InputStream in = fileItem.openStream();
            int len;
            byte[] buffer = new byte[8192];
            while ((len = in.read(buffer, 0, buffer.length)) != -1) {
              System.out.println("got " + len + " bytes");
              String tmp = new String(buffer, 0, len);
              file += tmp;
            }
          //file = fileItem.getString();
          break;
          }
      }
    } catch (Exception ex) {
      System.err.println("Error while reading uploaded file: " + ex);
    }
  }
%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <META name="keywords"
          content="GoogleMaps, Map, GPX, track, editor, online, GPS, upload, save, DHTML">
    <title>WTracks <%=host%>- Online GPX track editor</title>
    <link rel="shortcut icon" href="img/favicon.ico" />
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

    .graph-box{
      background: #eee;
      border: 1px solid black;
      padding: 10px;
      left: 10px;
      top: 75px;
      position: absolute;
      visibility: hidden;
    }

    #map {
      width: 100%;
      height: 100%;
    }

    body {
      position:absolute;
      width: 100%;
      height: 100%;
      top:0;
      left:0;
      margin:0
    }

    #header {
      height: auto;
      width: 100%;
    }
    #content {
      height: 100%;
      width: 100%;
    }
    #footer {
      height: auto;
      width: 100%;
    }
  </style>

    <!-- Google API license key -->
    <script src="http://maps.google.com/maps/api/js?sensor=true" type="text/javascript"></script>

  </head>
  <body onload="wt_load()">

    <table style="width:100%; height:100%; position:fixed; top:0; left:0">

    <tr id="header"><td>

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
      <%
        openID = getUserID(session);

        if ((openID == null) || (openID.length() == 0)) {
          openID = null;
      %>
      <a class="rpxnow" onclick="return false;"
        href="https://<%=rpxnow_realm%>.rpxnow.com/openid/v2/signin?token_url=<%=rpxnow_token_url%>">
        <img src="http://wiki.openid.net/f/openid-16x16.gif" alt="" border="0"> Sign In
      </a>
      <script type='text/javascript'>
        var oid = ''
      </script>
      <%
        } else {
      %>
      <script type='text/javascript'>
        var openID = <%= openID %>;
        var name = openID.profile.displayName;
        var oid = openID.profile.identifier;
        if (name == '') {
          name = oid.replace('http://', '');
        }
        document.write("<a href='" + oid + "'>" + name + "</a>");
      </script>
      | <a href='login.jsp?action=logout&<%=rpxgoto%>'>Logout</a><br>
      <%
        }
      %>
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
          <form onsubmit="return false">
          <th style="text-align:right">
              Show: <img src="img/mm_20_red.png" alt="handles" title="handles"/>
              <input type="checkbox" id="showmarkers"
              <% if (showmarkers) out.print("checked"); %>
              onclick="wt_showTrkMarkers(this.checked)" />
              &nbsp;/&nbsp; Labels
              <input type="checkbox" id="showlabels"
              <% if (showlabels) out.print("checked"); %>
              onclick="wt_showLabels(this.checked)" />
              &nbsp;/&nbsp; <img src="img/icon13noshade.gif" alt="waypoints" title="waypoints"/>
              <input type="checkbox" id="showwaypoints" checked
              onclick="wt_showWaypoints(this.checked)" />
          </th>
          </form>
        </tr>
      </table>

    </td></tr>
    <tr id="content"><td><div id="map"></div></td></tr>
    <tr id="footer"><td>

      <!-- PAGE FOOTER -->
        <!-- div style="position: absolute; bottom: 10px; right: 10px; left: 10px; top: auto;" -->
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
            <td width="60" id="altmax"></td>
            <th width="150">Climbing</th>
            <td width="60" id="climbing"></td><!-- name="submit" value="submit" -->
            <td rowspan="2"><button type="submit" onclick="wt_doGraph(); return false">2D Profile<br><img src="img/2d.gif"></button></td>
          </tr>
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
          <tr <% if (! debugging) out.print("style='display: none'"); %> >
            <form action="#" onsubmit="debug.set(''); return false">
            <td>
              <input type="submit" value="Clear debug" />
            </td>
            </form>
            <td colspan="6" id="debug">
            </td>
          </tr>
        </table>

        <hr />

        <script type="text/javascript">
        function doEmail2(d, i, tail) {
          location.href = "mailto:" + i + "@" + d + tail;
        }
        </script>

        <table width="100%">
          <tr style="font-size:small; font-family:sans-serif;" >
            <td>
              <a href="http://creativecommons.org/licenses/by/2.0/fr/deed.en_US"><img src="http://i.creativecommons.org/l/by/2.0/fr/80x15.png" border=0></a>
              <a href="javascript:doEmail2('gmail.com','Olivier.Potonniee','?subject=WTracks')">Olivier Potonni&eacute;e</a>
              - <a href="html/privacy.html">Privacy Policy</a>
              - <a href="http://code.google.com/p/wtracks/">Contribute</a>
            </td>
            <td align="right" style="display:none;">
            <i>URL syntax:</i> <%= "http" + (request.getServerPort() == 80 ? "": "s") + "://" + request.getServerName() + request.getRequestURI() %>[?gpx=&lt;gpx file url&gt;[&amp;marks=(true|false)][&amp;labels=(true|false)]
            </td>
          </tr>
        </table>

      <!--/div-->   <!-- FOOTER -->

    </td></tr></table>


    <div class="graph-box" id="graph-box" onkeydown='check_for_escape(event, "graph-box")'>
      <table>
        <tr>
          <th style="text-align:left">Track profile</th>
          <th align="right"><a href="javascript:close_popup('graph-box')">
              <img src="img/close.gif" alt="Close" title="Close" style="border: 0px"/></a></th>
        </tr>
        <tr><td colspan="2">
        <div><canvas id="graph" height="350" width="650"></canvas></div>
        </td></tr>
      </table>
    </div>


    <div class="options-box" id="load-box" onkeydown='check_for_escape(event, "load-box")' style="z-index:10;">
      <table>
        <tr>
          <th style="text-align:left">Load Options</th>
          <th><a href="javascript:close_popup('load-box')"><img src="img/close.gif" alt="Cancel and Close" title="Cancel and Close" style="border: 0px"/></a></th>
        </tr>
        <tr>
          <form onsubmit="wt_loadGPX(this.url.value, true); return false;">
            <td>
              <input type="submit" value="Load GPX from URL:" />
            </td><td>
              <input id="gpxurl" type="text" size="60" name="url" value="http://" />
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
<%
  if (openID != null) {
%>
        <tr>
          <td>
            Your saved track:
          </td><td>
            <span style="width:500px; max-height:300px; overflow:auto; display:inline-block;" id="usertracks-span"><img src='img/processing.gif'></span>
          </td>
        </tr>
<% } %>
      </table>
    </div>


    <div class="options-box" id="save-box" onkeydown='check_for_escape(event, "save-box")'>
      <table>
        <tr>
          <th style="text-align:left">Save Options</th>
          <th><a href="javascript:close_popup('save-box')"><img src="img/close.gif"
               alt="Cancel and Close" title="Cancel and Close" style="border: 0px"/></a></th>
        </tr>
        <tr>
          <td>Track Name</td>
          <form><td><input type="text" size="40" id="trackname" /></td></form>
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
          <form target="_blank" action="savegpx.jsp" method="post" onSubmit="wt_doSave()">
            <td colspan="2">
              <input type='hidden' id='savedname' name='savedname' value='' />
              <input type="submit" name="action" value="Save" />
<%
  if (openID != null) {
%>
<script type="text/javascript">
              document.write("<input type='hidden' name='oid' value='" + oid + "' />");
</script>
              <input type='submit' name='action' value='Save on this server' />
              <input type='checkbox' name='public' value='yes' /> Public
<% } else { %>
              (Sign in to be able to save on this server)
<% } %>
              <textarea name="gpxarea" class="hidden"
                        id="gpxarea" readonly rows="20" cols="80"><%

  if (file != null) {
     out.print(file); // the uploaded file content
  }
%></textarea>
            </td>
          </form>
        </tr>
      </table>
    </div>

  <!-- GOOGLE ANALYTICS -->
  <script type="text/javascript">
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '<%=ganalytics_key%>']);
    _gaq.push(['_trackPageview']);
    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
  </script>
  <!-- END OF GOOGLE ANALYTICS -->

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
  var cluster;
  var geocoder;
  var infoWindow;

  var info; // info line
  var debug; // debug area

  var ROUNDTRIP_IMG = "<img src='img/roundtrip.png' alt='Round Trip' title='Round Trip'>";
  var ONEWAY_IMG = "<img src='img/oneway.png' alt='One Way' title='One Way'>";
  var WTRACKS = "WTracks - Online GPX track editor"

  //  wpt icon
  var wp_icon = new google.maps.MarkerImage("img/icon13.png") // http://maps.google.com/mapfiles/kml/pal2/
  var wp_icon_shadow = new google.maps.MarkerImage("img/icon13s.png") // http://maps.google.com/mapfiles/kml/pal2/

  //  wpt icon
  var trkpt_icon = new google.maps.MarkerImage("img/mm_20_red.png");
  var trkpt_icon_shadow = new google.maps.MarkerImage("img/mm_20_shadow.png");

  /*------------ Utility functions -----------*/

  function getAltitude(lat, lng) {
    // http://ws.geonames.org/srtm3?lat=<lat>&lng=<lng>
    //"http://ws.geonames.org/srtm3?lat="+lat+"&lng="+lng
    var url = "http://maps.google.com/maps/api/elevation/json?sensor=false&locations="+lat+","+lng

    var request = Lokris.AjaxCall("httprawget_proxy.jsp?"+escape(url), null, {async: false});
    debug.add("#")
    debug.add(" status:" + request.status)
    var res = 0
    if ((request.status == 200) && (request.responseText)) {
      debug.add(" text: " + request.responseText)
      var resp = eval("(" + request.responseText + ")")
      if (resp.status == "OK") {
        res = resp.results[0].elevation
      }
    }
    return res;
  }

  function setTrackName(name) {
    document.title = WTRACKS + (name ? (" - " + name) : "")
    setElement("trktitle", name)
  }

  function addTrackLink(gpxURL) {
    name = document.getElementById("trktitle").innerHTML;
    setElement("trktitle", "<a href='?gpx=" + gpxURL + "&marks=" + areMarkersShown() + "&labels=" + areLabelsShown() + "'>" + name + "</a>")
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
    var a = trkpt2.getPosition().distanceFrom(trkpt1.getPosition());
    var b = trkpt2.wt_alt() - trkpt1.wt_alt();
    return Math.sqrt((a*a) + (b*b));
  }

  // Add '0' before values below 10
  function lead0( v ) {
    if (v < 10) return "0" + v;
    return v;
  }

  function mapIt(p, always) {
    if (true || always) {
      p.setMap(map);
    } else {
      cluster.addMarker(p);
      p.clustered = true
    }
  }
  function unmapIt(p) {
    if (p.clustered) {
      cluster.removeMarker(p);
      p.clustered = undefined;
    } else {
      p.setMap(null);
    }
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

  /* GMaps API v2 compatibility */

  google.maps.LatLng.prototype.distanceFrom = function(newLatLng) {
    //var R = 6371; // km (change this constant to get miles)
    var R = 6371000; // meters
    var lat1 = this.lat();
    var lon1 = this.lng();
    var lat2 = newLatLng.lat();
    var lon2 = newLatLng.lng();
    var dLat = (lat2-lat1) * Math.PI / 180;
    var dLon = (lon2-lon1) * Math.PI / 180;
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(lat1 * Math.PI / 180 ) * Math.cos(lat2 * Math.PI / 180 )  *  Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    var d = R * c;
    return d;
  }

  function openInfoWindow(pos, html) {
    closeInfoWindow();
    var infoOpts = {
      content: html,
      disableAutoPan: false,
      position: pos
    }
    infoWindow = new google.maps.InfoWindow(infoOpts)
    infoWindow.open(map);
  }

  function closeInfoWindow() {
    if (infoWindow) {
      infoWindow.close();
      infoWindow = undefined;
    }
  }
  
/*------------ Wpt --------------*/

  function toPt(marker, i) {
    marker.wt_manalt = undefined
    marker.wt_name = undefined
    marker.wt_i = i
    // click event
    google.maps.event.addListener(marker, "click", function() {
      wt_showInfo(marker, true)
    });
    // drag event
    google.maps.event.addListener(marker, "dragend", function() {
      marker.wt_relocate(false)
    });
    // drag event
    google.maps.event.addListener(marker, "drag", function() {
      marker.wt_relocate(false)
    });

    // show marker
    marker.wt_showMarker(true);
  }

  google.maps.Marker.prototype.Wt_getName = function() {
    return (this.wt_name ? this.wt_name : "");
  }

  google.maps.Marker.prototype.Wpt_relocate = function(openinfo) {
    closeInfoWindow();
    if (openinfo) {
      this.wt_showInfo(true);
    }
  }


  google.maps.Marker.prototype.wt_infoHead = function() {
    var ptinfo = "Name: <input type='text' size='10' value='" + this.Wt_getName()
        + "' onchange='"+ this.wt_arrayname + "[" + this.wt_i + "].wt_setName(this.value)' onkeyup='"
        + this.wt_arrayname + "[" + this.wt_i + "].wt_setName(this.value)'/><br/>";
    ptinfo += "Position: <span id='ppos'>" + this.getPosition().toUrlValue() + "</span><br/>";
    return ptinfo
  }

  google.maps.Marker.prototype.Wpt_showInfo = function(openinfo) {
     current_trkpt = undefined
     info.set("");
     if (openinfo) {
       var ptinfo = "<form style='font-size:smaller' onsubmit='return false'>";

       ptinfo += this.wt_infoHead()
       ptinfo += "Altitude: <span id='altv'>" + this.wt_altview() + "</span>";
       ptinfo += " <a href='javascript:wpts[" + this.wt_i + "].Wpt_setAltDB();'>alt DB</a>";
       ptinfo += "</form><div style='margin:2px'>";
       ptinfo += "<a href='javascript:wpts[" + this.wt_i + "].Wpt_delete();'>Delete</a> - ";
       ptinfo += "<a href='javascript:wpts[" + this.wt_i + "].Wpt_duplicate();'>Duplicate</a>";
       ptinfo += "</div>";
       
       openInfoWindow(this.getPosition(), ptinfo)
    }
  }

  google.maps.Marker.prototype.Wpt_altview = function() {
    var scripttxt = this.wt_arrayname + "[" + this.wt_i + "].wt_setAlt(false, this.value); wt_showInfo("
                    + this.wt_arrayname + "[" + this.wt_i + "],false)"
    var alt = this.wt_alt()
    if (alt == undefined) alt = ""
    return "<input type='text' size='4' name='alt' value='" + alt + "' onchange='" + scripttxt + "' onkeyup='" + scripttxt + "'/>";
  }

  google.maps.Marker.prototype.wt_updateTitle = function() {
    var title = "";
    if (this.wt_name && this.wt_name != "") title += this.wt_name;
    if ((this.wt_manalt != undefined) && (this.wt_autoalt == undefined || !this.wt_autoalt)) {
      title += " (" + this.wt_manalt + "&nbsp;m)";
    }
    if (title != "") {
      this.set("labelContent", title)
      this.set("labelAnchor", new google.maps.Point(10, 0))
      this.set("labelClass", "ptlabel")
    } else {
      this.set("labelContent", "")
    }
  }

  google.maps.Marker.prototype.wt_setName = function(name) {
    this.wt_name = name;
    this.wt_updateTitle();
  }

  google.maps.Marker.prototype.Wpt_setAlt = function(auto, man) {
    this.wt_manalt = man ? parseFloat(man) : undefined;
    this.wt_autoalt = auto;
    this.wt_updateTitle();
  }

  google.maps.Marker.prototype.Wpt_setAltDB = function() {
    this.wt_setAlt(false, getAltitude( this.getPosition().lat(), this.getPosition().lng() ));
    wt_showInfo(this, true)
  }

  google.maps.Marker.prototype.wt_updateAutoalt = function(newautoalt) {
    //debug.set("i=" + i + ", newautoalt=" + newautoalt);
    this.wt_setAlt(newautoalt, this.wt_alt());
    wt_showInfo(this, false)
    var altv = document.getElementById("altv");
    altv.innerHTML = this.wt_altview();
  }

  google.maps.Marker.prototype.wt_showMarker = function(isnew) {
    if (this.wt_areMarkersShown()) {
      // show marker
      mapIt(this);
    } else if (!isnew) {
      mapIt(this)
    }
  }

  google.maps.Marker.prototype.Wpt_alt = function() {
    return this.wt_manalt
  }

  google.maps.Marker.prototype.Wpt_duplicate = function() {
    var pos = new google.maps.LatLng(this.getPosition().lat()+0.0001, this.getPosition().lng()+0.0001)
    var pt = new_Wpt(pos)
    pt.wt_manalt = this.wt_manalt
    pt.wt_setName(this.wt_name)
    wt_showInfo(this, true)
    openInfoWindow(pos, "Duplicated point");
  }

  google.maps.Marker.prototype.Wpt_delete = function() {
    closeInfoWindow();
    var newwpts = [];

    for (i=0; i < wpts.length; i++) {
     if (i != this.wt_i){
       wpts[i].wt_i = newwpts.length
       newwpts.push(wpts[i])
     }
    }
    unmapIt(this);
    wpts = newwpts
  }

  google.maps.Marker.prototype.toWpt = function(i) {
    this.dummy = "dummy"
    this.wt_arrayname = "wpts"
    this.wt_gpxelt = "wpt"
    this.wt_relocate = google.maps.Marker.prototype.Wpt_relocate
    this.wt_showInfo = google.maps.Marker.prototype.Wpt_showInfo
    this.wt_alt = google.maps.Marker.prototype.Wpt_alt
    this.wt_altview = google.maps.Marker.prototype.Wpt_altview
    this.wt_areMarkersShown = areWptsShown
    this.wt_areLabelsShown = areWptsShown
    this.wt_setAlt = google.maps.Marker.prototype.Wpt_setAlt

    toPt(this, i)
    this.wt_updateTitle();
  }

  google.maps.Marker.prototype.wt_toGPX = function(savealt, savetime) {
    var gpx = "<" + this.wt_gpxelt + " ";
    gpx += "lat=\"" + this.getPosition().lat() + "\" lon=\"" + this.getPosition().lng() + "\">";
    if (this.wt_name) {
      gpx += "<name>" + htmlEncode(this.wt_name, false, 0)  + "</name>";
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
    var markOpts = {
      draggable: true,
      icon: wp_icon,
      shadow: wp_icon_shadow,
      position: point,
      title: name,
      labelContent:name?name:"",
      visible: true
    }
    var pt = new MarkerWithLabel(markOpts)
    pt.toWpt(wpts.length)
    wpts.push(pt)
    if (alt) pt.wt_setAlt(false, alt)
    if (name) pt.wt_setName(name)
    return pt
  }


 /*------------- Trkpt ------------*/

  google.maps.Marker.prototype.Trkpt_altview = function() {
    if (this.wt_autoalt) {
      return this.wt_alt();
    } else {
      return this.Wpt_altview();
    }
  }

  google.maps.Marker.prototype.Trkpt_setAlt = function(auto, man) {
    this.Wpt_setAlt(auto, man)
    // update infos from last known alt point
    var i = this.wt_i > 0 ? this.wt_i-1 : 0
    while ((i > 0) && (trkpts[i].wt_autoalt)) {
      i--
    }
    wt_updateInfoFrom(trkpts[i])
  }

  google.maps.Marker.prototype.Trkpt_relocate = function(openinfo) {
    closeInfoWindow();
    points[this.wt_i] = this.getPosition();
    wt_drawPolyline();
    wt_updateInfoFrom(this)
    if (openinfo) {
      wt_showInfo(this, true);
    } else {
      wt_showInfo(undefined, false);
    }
  }

  google.maps.Marker.prototype.Trkpt_updateAlt = function() {
    // --- altitude
    if (this.wt_autoalt) {
      if ((this.wt_i > 0) && ((this.wt_i + 1) < trkpts.length)) {
        var previ = this.wt_i-1;
        var prevdist = trkpts[previ].getPosition().distanceFrom(this.getPosition());
        while ((previ > 0) && trkpts[previ].wt_autoalt) {
          previ--;
          prevdist += trkpts[previ].getPosition().distanceFrom(
                        trkpts[previ+1].getPosition());
        }
        var nexti = this.wt_i+1;
        var nextdist = trkpts[nexti].getPosition().distanceFrom(this.getPosition());
        while ((nexti < (trkpts.length - 1)) && trkpts[nexti].wt_autoalt) {
          nexti++;
          nextdist += trkpts[nexti].getPosition().distanceFrom(
                       trkpts[nexti-1].getPosition());
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
  google.maps.Marker.prototype.Trkpt_updateDistance = function() {
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
  google.maps.Marker.prototype.Trkpt_updateTime = function() {
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

  google.maps.Marker.prototype.Trkpt_updateTime_rt = function() {
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

  google.maps.Marker.prototype.Trkpt_showInfo = function(openinfo) {
     current_trkpt = this
     if (openinfo) {

       var ptinfo = "<form style='font-size:smaller' onsubmit='return false'>";
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
       ptinfo += "</form>\n";
       ptinfo += "Distance from start: <span id='pdistt'>" + showDistance(this.wt_tdist) + "</span>";
       if (this.wt_i > 0) {
         ptinfo += "(<span id='pdistr'>" + showDistance(this.wt_rdist) + "</span> from last)";
       }
       ptinfo += "<div style='margin:2px'>";
       if (this.wt_i > 0) {
         ptinfo += "<a href='javascript:trkpts[0].Trkpt_showInfo(true)'>|&lt</a>&nbsp;";
         ptinfo += "<a href='javascript:trkpts[" + (this.wt_i-1) + "].Trkpt_showInfo(true)'>&lt&lt</a>&nbsp;";
       }
       ptinfo += "<a href='javascript:trkpts[" + this.wt_i + "].Trkpt_delete()'>Delete</a> - ";
       ptinfo += "<a href='javascript:trkpts[" + this.wt_i + "].Trkpt_duplicate()'>Duplicate</a> - ";
       ptinfo += "<a href='javascript:trkpts[" + this.wt_i + "].Trkpt_detach()'>Detach</a>\n";
       if (this.wt_i < trkpts.length -1) {
         ptinfo += "&nbsp;<a href='javascript:trkpts[" + (this.wt_i+1) + "].Trkpt_showInfo(true)'>&gt;&gt;</a>";
         ptinfo += "&nbsp;<a href='javascript:trkpts[" + (trkpts.length-1) + "].Trkpt_showInfo(true)'>&gt;|</a>\n";
       }
       ptinfo += "</div>";

       openInfoWindow(this.getPosition(), ptinfo);
    } else {
      document.getElementById("pdistt").innerHTML = showDistance(this.wt_tdist)
      document.getElementById("pdistr").innerHTML = showDistance(this.wt_rdist)
      document.getElementById("ptime").innerHTML = showTime(this.wt_time())
      if (isroundtrip && (this.wt_time_rt() != this.wt_time())) {
        document.getElementById("ptime_rt").innerHTML = showTime(this.wt_time_rt())
      }
    }
  }


  google.maps.Marker.prototype.Trkpt_detach = function() {
    var pt = new_Wpt(this.getPosition(), this.wt_manalt, this.wt_name)
    this.Trkpt_delete()
    wt_showInfo(undefined, false)
    pt.wt_showInfo(true)
  }

  google.maps.Marker.prototype.Trkpt_duplicate = function() {
    closeInfoWindow();
    var newpoints = [];
    var newtrkpts = [];
    var pt
    var pos
    for (i=0; i < trkpts.length; i++) {
     trkpts[i].wt_i = newtrkpts.length
     newtrkpts.push(trkpts[i])
     newpoints.push(trkpts[i].getPosition())
     if (i == this.wt_i){
       pos = new google.maps.LatLng(trkpts[i].getPosition().lat()+0.0001, trkpts[i].getPosition().lng()+0.0001)
       var markOpts = {
          draggable: true,
          icon: trkpt_icon,
          shadow: trkpt_icon_shadow,
          position: pos,
          labelContent:"",
          visible: true
       }
       pt = new MarkerWithLabel(markOpts)
       pt.toTrkpt(newtrkpts.length)
       pt.wt_i = newtrkpts.length
       newtrkpts.push(pt)
       newpoints.push(pos)
       openInfoWindow(pos, "Duplicated point");
     }
    }
    points = newpoints;
    trkpts = newtrkpts
    wt_updateInfoFrom(pt)
    wt_drawPolyline();
  }

  google.maps.Marker.prototype.Trkpt_delete = function() {
    closeInfoWindow();
    var newpoints = [];
    var newtrkpts = [];
    for (i=0; i < trkpts.length; i++) {
     if (i != this.wt_i){
       trkpts[i].wt_i = newtrkpts.length
       newtrkpts.push(trkpts[i])
       newpoints.push(trkpts[i].getPosition())
     }
    }
    unmapIt(this);
    points = newpoints;
    trkpts = newtrkpts
    wt_drawPolyline();
    if (this.wt_i > 0) {
      wt_updateInfoFrom(trkpts[this.wt_i - 1])
    }
    wt_showInfo(undefined, false)
  }


  google.maps.Marker.prototype.Trkpt_alt = function() {
    return this.wt_manalt ? this.wt_manalt : 0
  }

  google.maps.Marker.prototype.wt_time = function() {
    return this.wt_mantime;
  }

  google.maps.Marker.prototype.wt_time_rt = function() {
    return this.wt_mantime_rt;
  }

  google.maps.Marker.prototype.toTrkpt = function(i) {
    this.wt_arrayname = "trkpts"
    this.wt_gpxelt = "trkpt"
    this.wt_relocate = google.maps.Marker.prototype.Trkpt_relocate
    this.wt_showInfo = google.maps.Marker.prototype.Trkpt_showInfo
    this.wt_alt = google.maps.Marker.prototype.Trkpt_alt
    this.wt_altview = google.maps.Marker.prototype.Trkpt_altview
    this.wt_areMarkersShown = areMarkersShown
    this.wt_areLabelsShown = areLabelsShown
    this.wt_setAlt = google.maps.Marker.prototype.Trkpt_setAlt
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
    var markOpts = {
      draggable: true,
      icon: trkpt_icon,
      shadow: trkpt_icon_shadow,
      position: point,
      title: name,
      labelContent:name?name:"",
      visible: true
    }
    var pt = new MarkerWithLabel(markOpts)
    pt.toTrkpt(trkpts.length, alt, name)
    trkpts.push(pt)
    points.push(pt.getPosition())
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
    gpx += '  <link href="http://<%=host%>">\n'
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
      unmapIt(polyline);
    }
    if (points && points.length > 0) {
      var lineOpts = {
        clickable:false,
        path:points,
        strokeColor:"#FF0000",
        strokeWeight:5
      }
      polyline = new google.maps.Polyline(lineOpts);
      mapIt(polyline, true);
    } else {
      polyline = undefined
    }
  }

  function wt_clear() {
    closeInfoWindow();
    var i = 0
    while (i < trkpts.length) {
      unmapIt(trkpts[i]);
      i++
    }
    i = 0
    while (i < wpts.length) {
      unmapIt(wpts[i]);
      i++
    }
    if (polyline) unmapIt(polyline);
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

 
  function wt_loadGPX(filename, link) {
    close_popup('load-box');
    //info.set("loading " + filename + "...<br>");
    info.set("<img src='img/processing.gif'> Loading...");
    downloadUrl("httpget_proxy.jsp?" + filename, function(data, responseCode) {
      if (wt_importGPX(data) && link) {
        addTrackLink(filename);
      }
    });
  }

  function wt_loadUserGPX(filename, useroid) {
    close_popup('load-box');
    //info.set("loading " + filename + "...<br>");
    info.set("<img src='img/processing.gif'> Loading...");
    downloadUrl("usertracks.jsp?oid=" + useroid + "&name=" + filename, function(data, responseCode) {
      wt_importGPX(data);
    });
  }

  function wt_importPoints(xmlpts, is_trk) {
    var point;
    for (var i = 0; i < xmlpts.length; i++) {
      point = new google.maps.LatLng(parseFloat(xmlpts[i].getAttribute("lat")),
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
      if (!gpxinput) {
        info.add("Failed to read file<br>")
        return
      }
      info.add("Importing... <br>");
      var xml
      if (gpxinput.firstChild) {
        xml = gpxinput;
      } else {
        xml = xmlParse(gpxinput);
      }
      var gpx = xml ? xml.getElementsByTagName("gpx") : undefined
      //debug.set("gpxinput:<textarea width='40' height='20'>" + gpxinput + "</textarea>")
      debug.add("xml:" + xml)
      if (!xml.documentElement || !gpx || (gpx.length == 0)) {
        info.add("The file is not in gpx format<br>")
        return false
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
        var center = new google.maps.LatLng(0,0)
        var zoom = 10
        var mapbounds = new google.maps.LatLngBounds();
        if (bounds && bounds.length > 0) {
          //debug.add(bounds.length)
          var sw = new google.maps.LatLng(parseFloat(bounds[0].getAttribute("minlat")),
                               parseFloat(bounds[0].getAttribute("minlon")))
          var ne = new google.maps.LatLng(parseFloat(bounds[0].getAttribute("maxlat")),
                               parseFloat(bounds[0].getAttribute("maxlon")))
          mapbounds = new google.maps.LatLngBounds(sw, ne)
        } else {
          // compute bounds to include all trackpoints and waypoints
          if (trkpts) {
            for(var i = 0; i < trkpts.length; i++) {
              mapbounds.extend(trkpts[i].getPosition());
            }
          }
          if (wpts) {
            for(var i = 0; i < wpts.length; i++) {
              mapbounds.extend(wpts[i].getPosition());
            }
          }
        }
        //center = mapbounds.getCenter()
        //zoom = Math.max(map.getBoundsZoomLevel(mapbounds),15)
        zoom = map.fitBounds(mapbounds)
        //map.setCenter(center, zoom);
        if (trkpts && trkpts.length > 0) {
          var pt = trkpts[trkpts.length - 1];
          wt_drawPolyline();
          wt_showInfo(pt, true);
        }
        info.set("");
        return true;
      } else {
        info.set("Can't read GPX input file");
        return false;
      }
  }

  function wt_showTrkMarkers(show) {
    //closeInfoWindow();
    var i = 0;
    while (i < trkpts.length) {
      if (show) {
        mapIt(trkpts[i]);
      } else {
        unmapIt(trkpts[i]);
      }
      i++;
    }
  }

  function wt_showLabels(show) {
    //closeInfoWindow();
    var i = 0;
    while (i < trkpts.length) {
      trkpts[i].set("labelVisible", show);
      i++;
    }
  }

  function wt_showWaypoints(show) {
    //closeInfoWindow();
    var i = 0;
    while (i < wpts.length) {
      if (show) {
        mapIt(wpts[i]);
      } else {
        unmapIt(wpts[i]);
      }
      i++;
    }
  }

  function wt_showAddress(addr) {
    geocoder.geocode(
      {address:addr},
      function(res) {
        var geo = res[0].geometry;
        if (!geo) {
          alert(address + " not found");
        } else {
          map.setCenter(geo.location);
          map.setZoom(13);
          openInfoWindow(geo.location, addr);
        }
      }
      );
      /*
    geocoder.getLatLng(
      address,
      function(point) {
        if (!point) {
          alert(address + " not found");
        } else {
          map.setCenter(point, 13);
          openInfoWindow(point, address);
        }
      }
    );
    */
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
    info = new DocElement("message");
    debug = new DocElement("debug");

    var mapDiv = document.getElementById("map")
    var mapOptions = {
      zoom: 3,
      center: new google.maps.LatLng(0,0),
      mapTypeId: google.maps.MapTypeId.HYBRID,
      scrollwheel: true,
      disableDoubleClickZoom:false
    }
    map = new google.maps.Map(mapDiv, mapOptions);
    //cluster = new MarkerClusterer(map, [], {maxZoom:13, zoomOnClick: false});

    //----- Stop page scrolling if wheel over map ----
    google.maps.event.addDomListener(mapDiv, "DOMMouseScroll", wheelevent);
    mapDiv.onmousewheel = wheelevent;

    geocoder = new google.maps.Geocoder();

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

    // click events

    // right click: create track point
    google.maps.event.addListener(map, "rightclick", function(event) {
      var pt = new_Trkpt(event.latLng);
      wt_drawPolyline();
      wt_showInfo(undefined, false);
    });
    
    // left click: close info window
    google.maps.event.addListener(map, "click", function(event) {
      closeInfoWindow()
      close_popup("save-box");
      close_popup("load-box");
      close_popup("graph-box")
    })
    
<%
if (!"".equals(file)) {
    out.println("info.set('Uploaded " + file_name + "<br>')");
%>
    wt_importGPX(document.getElementById('gpxarea').value, false);
<%
} else {
%>

    var useroid="<%= ((request.getParameter("oid") == null) ? "" : request.getParameter("oid")) %>";
    var usertrack="<%= ((request.getParameter("name") == null) ? "" : request.getParameter("name")) %>";
    var gpxLink = false;
    if ((useroid.length>1) && (usertrack.length>1)) {
      wt_loadUserGPX(escape(usertrack), escape(useroid));
    } else {
      var gpxurl="<%= ((request.getParameter("gpx") == null) ? "" : request.getParameter("gpx")) %>";
      if (gpxurl.length>1) {
        debug.add(gpxurl);
        //document.getElementById("showmarkers").checked = false;
        gpxLink = true;
      } else {
        gpxurl = "tracks/everest.gpx";
      }
      wt_loadGPX(gpxurl, gpxLink);
    }
<%
}
%>
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
    if (!infoWindow) {
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
    //alert(String.fromCharCode(e.keyCode))
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
    close_popup("graph-box");
    show_popup("save-box");
    var obj = document.getElementById("trackname");
    obj.focus();
  }

  function wt_doSave() {
    close_popup('save-box')
    trackname = htmlEncode(document.getElementById("trackname").value, false, 0)
    document.getElementById("savedname").value = trackname
    var savealt = document.getElementById("savealt").checked
    var savetime = document.getElementById("savetime").checked
    document.getElementById("gpxarea").value = wt_toGPX(savealt, savetime)
  }

  function show_user_tracks(res) {
    document.getElementById("usertracks-span").innerHTML = res;
  }

  function load_tracks(params) {
    document.getElementById("usertracks-span").innerHTML = "<img src='img/processing.gif'>";
    Lokris.AjaxCall("usertracks.jsp" + params, show_user_tracks,
              { method: "POST", postBody: "oid="+oid });
  }

  function delete_track(url) {
    if (confirm("Delete track '" + url + "'?")) {
      load_tracks('?delete=' + url);
    }
  }

  function show_load_box(){
    if (oid != "") {
      load_tracks("");
    }
    close_popup("save-box");
    close_popup("graph-box");
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
    close_popup("save-box");
    close_popup("load-box");
    show_popup("graph-box")
  }

    //]]>
    </script>

   <script src="js/htmlEncode.js" type="text/javascript"></script>
   <script src="js/showmail.js" type="text/javascript"></script>
   <script src="js/util.js" type="text/javascript"></script>

<!-- plotkit includes (for graph disply) -->
   <script src="js/MochiKit.js" type="text/javascript"></script>
   <script src="js/excanvas.js" type="text/javascript"></script>
   <script src="js/PlotKit_Packed.js" type="text/javascript"></script>
<!-- end of plotkit includes -->

<!-- utility scripts -->
   <script src="js/lokris.js" type="text/javascript"></script>
   <script src="js/markerwithlabel.js" type="text/javascript"></script>
   <!-- script src="js/markerclusterer.js" type="text/javascript"></script -->

  <!-- RPXNOW -->
<script src="https://rpxnow.com/openid/v2/widget"
        type="text/javascript"></script>
<script type="text/javascript">
  RPXNOW.token_url = "http://<%= host + rpxnow_token_url %>";
  RPXNOW.realm = "<%=rpxnow_realm%>";
  RPXNOW.overlay = true;
  RPXNOW.language_preference = 'en';
</script>
  <!-- END OF RPXNOW -->

</html>

