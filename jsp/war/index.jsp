<%@ page import="java.util.*, java.io.*, java.util.logging.Logger" %>
<%!
    static Logger log = Logger.getLogger("index");
%>
<%
  // ===============================================================================
  // Convert GET with parameters to POST
  Enumeration<String> paramNames = request.getParameterNames();
  if ("GET".equalsIgnoreCase(request.getMethod()) && paramNames.hasMoreElements()) {
%>
<html lang="en">
<head>
<meta charset='utf-8'>
<link rel="shortcut icon" href="img/favicon.ico" />
</head>
<body>
<div style="display: none"><form action="/" method="post">
<%
    while (paramNames.hasMoreElements()) {
      String pname = paramNames.nextElement();
      out.println("<input type='text' name='" + pname + "' value='" + request.getParameter(pname) + "' />");
    }
%>
<input type="submit"/></form></div>
<script type="text/javascript">document.forms[0].submit();</script>
</body></html>
<%
    return;
  }



  // ===============================================================================
    Cookie[] cookies = request.getCookies();
    int[] stepTimes = new int[] {
      86400, // 24h
      604800, // 1 week
      2419200, // 1 month
      14515200 // 6 month
    };
    boolean hasDonateCookie = false;
    int stepDonateCookie = 0;
    if (cookies != null) {
      try {
        for(int i = 0; i < cookies.length; i++) {
        Cookie c = cookies[i];
          if (c.getName().equals("wt_t")) {
            hasDonateCookie = true;
          } else if (c.getName().equals("wt_s")) {
            stepDonateCookie = Integer.parseInt(c.getValue());
          }
        }
      } catch (Exception ex) {
        hasDonateCookie = false;
        stepDonateCookie = 0;
      }
    }

    boolean showDonatePopup = false;
    if (!hasDonateCookie) {
      // Set cookies
      Cookie ck_t = new Cookie("wt_t", "1");
      ck_t.setMaxAge(stepTimes[stepDonateCookie]);
      response.addCookie(ck_t);

      if (stepDonateCookie+1 < stepTimes.length) {
        stepDonateCookie++;
      }
      Cookie ck_s = new Cookie("wt_s", "" + stepDonateCookie);
      ck_s.setMaxAge(29030400); // 1 year
      response.addCookie(ck_s);

      showDonatePopup = true;
    }


  // ===============================================================================
  String appUrl = getAppUrl(request);

  String rpxgoto = "goto=" + java.net.URLEncoder.encode(getContextPath(request));
  String rpxnow_token_url = "/login.jsp?" + rpxgoto;


  // The following config file should set gmaps_key, ganalytics_key, rpxnow_realm and rpxnow_key
%>
<%@ include file="userid.jsp" %>
<%@ include file="includeFile.jsp" %>

<%
  boolean isLoggedIn = getUserID(session) != null;
  String userName = getUserName(session);

%>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset='utf-8'>
    <link rel="shortcut icon" href="img/favicon.ico" />
    <meta http-equiv="x-ua-compatible" content="IE=edge" >
    <meta name="viewport" content="width=device-width,height=device-height, user-scalable=no" />
    <META name="keywords" content="GoogleMaps, Map, GPX, GPS, Tracks, Trails, GIS, outdoor">
    <title>WTracks - Online GPX track editor</title>
    <script src="js/htmlEncode.js" type="text/javascript"></script>
    <link rel="stylesheet" type="text/css" href="wtracks.css">

    <!-- Google API license key -->
    <script src="https://maps.googleapis.com/maps/api/js?v=3&key=<%=gmaps_key%>&libraries=geometry"></script>

    <!-- Janrain RPX widget -->
    <script type="text/javascript">
    (function() {
        if (typeof window.janrain !== 'object') window.janrain = {};
        if (typeof window.janrain.settings !== 'object') window.janrain.settings = {};

        janrain.settings.tokenUrl = "<%=appUrl + rpxnow_token_url%>";

        function isReady() { janrain.ready = true; };
        if (document.addEventListener) {
          document.addEventListener("DOMContentLoaded", isReady, false);
        } else {
          window.attachEvent('onload', isReady);
        }

        var e = document.createElement('script');
        e.type = 'text/javascript';
        e.id = 'janrainAuthWidget';

        if (document.location.protocol === 'https:') {
          e.src = 'https://rpxnow.com/js/lib/wtracks/engage.js';
        } else {
          e.src = 'http://widget-cdn.rpxnow.com/js/lib/wtracks/engage.js';
        }

        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(e, s);
    })();
    </script>
    <!-- end rpx -->

  </head>
  <body onload="wt_load()" onunload="savePosition()">

    <table style="width:100%; height:100%; position:fixed; top:0; left:0">

    <tr id="header"><td>

      <!-- =================== end of Top bar =================== -->

      <table width="100%" style="border-collapse: collapse">
        <tr>
          <th style="text-align:left;">
            <a onclick="toggle_menu(); return false;"><img src="img/menu-icon.png"/></a>
            <span class="title" id="trktitle"></span>
          </th>
          <th style="text-align:right">
            <!-- login (rpxnow) -->
            <%
              if (isLoggedIn) {
            %>
              <a id='userid' href='#' onclick='toggle_user_box()'><%=userName%></a>
            <%
              } else {
            %>
              <a class="janrainEngage" href="#">Sign-In</a>
            <%
              }
            %>
            <!-- login (rpxnow) -->
          </th>
        </tr>
      </table>

    </td></tr>
    <tr id="content"><td><div id="map"></div></td></tr>
    <tr id="footer"><td>

      <!-- PAGE FOOTER -->
        <table id="statistics">
          <tr>
            <th>Distance</th>
            <td title='One Way'>
              <span id="distow"></span>
            </td>
            <td title='Round Trip'>
              <span id="distrt"></span>
            </td>
            <th>Alt. Max</th>
            <td id="altmax"></td>
            <th>Climbing</th>
            <td id="climbing"></td><!-- name="submit" value="submit" -->
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
            <td title='One Way'>
              <span id="timeow"></span>
            </td>
            <td title='Round Trip'>
              <span id="timert"></span>
            </td>
            <th>Alt. Min</th>
            <td id="altmin">
            </td>
            <th>Descent</th>
            <td id="descent">
            </td>
          </tr>
        </table>

      <!--/div-->   <!-- FOOTER -->

    </td></tr></table>


    <div class="graph-box" id="graph-box" onkeydown='check_for_escape(event, "graph-box")'>
      <table class="box-table">
        <tr>
          <th>Track profile</th>
          <th align="right"><a href="javascript:close_popup('graph-box')">
              <img src="img/close.gif" alt="Close" title="Close" style="border: 0px"/></a></th>
        </tr>
        <tr><td colspan="2">
        <div><canvas id="graph" height="350" width="650"></canvas></div>
        </td></tr>
      </table>
    </div>

    <div class="options-box" id="info" onkeydown='check_for_escape(event, "info")'>
      <table class="box-table">
        <tr>
          <th>Information Message</th>
          <th><a href="javascript:close_popup('info')"><img src="img/close.gif" alt="Close" title="Close" style="border: 0px"/></a></th>
        </tr>
      </table>
      <div id="message"></div>
    </div>

    <div id="user-box" onkeydown='check_for_escape(event, "user-box")'>
      <div><a href='login.jsp?action=logout&<%=rpxgoto%>' rel="nofollow">Logout</a></div>
    </div>

    <div class="options-box" id="menu" onkeydown='check_for_escape(event, "menu")'>
      <ul id="menu-list">
        <li><a href="https://opoto.github.io/wtracks" class="blink_me">Try new version</a></li>
        <li><a href="#" onclick="clear_track(); return false;">New</a></li>
        <li><a href="#" onclick="show_load_box(); return false;">Load</a></li>
        <li><a href="#" onclick="show_save_box(); return false;">Save</a></li>
        <li><a href="#" onclick="show_box('view-box'); return false;">View</a></li>
        <li><a href="#" onclick="show_tools_box(); return false;">Tools</a></li>
        <li><a href="html/privacy.html" target="_blank">Privacy</a></li>
        <li><a href="#" onclick="show_box('about-box'); return false;">About</a></li>
        <li><a href="#" onclick="show_box('donate-box'); return false;">Donate!</a></li>
        <li id="liRemember"><span>
          <input type="checkbox" id="remember" onclick="remember()"/><label for="remember">Remember me</label>
        </span></li>
      </ul>
    </div>

    <div class="options-box" id="view-box" onkeydown='check_for_escape(event, "view-box")' style="z-index:10;">
      <table class="box-table">
        <tr>
          <th>View</th>
          <th><a href="javascript:close_popup('view-box')"><img src="img/close.gif" alt="Close" title="Close" style="border: 0px"/></a></th>
        </tr>
        <tr>
          <form action="#" onsubmit="wt_showAddress(this.address.value); return false">
            <td style="text-align:right">
              <input type="submit" value="Go To Location:" />
            </td><td>
              <input type="text" size="30" name="address" value="" />
              <input type="button" onclick="this.form.address.value = ''; gotoMyLocation()" value="&#8857;" title="My Location"/>
            </td>
          </form>
        </tr>
        <tr>
          <td style="text-align:right">
            <input type="checkbox" id="showmarkers"
              onclick="storeVal('markers', this.checked); wt_showTrkMarkers(this.checked)" />
          </td><td>
            <label for="showmarkers"><img src="img/mm_20_red.png" alt="handles" title="handles"/>&nbsp; Show track markers</label>
          </td>
        </tr>
        <tr>
          <td style="text-align:right">
            <input type="checkbox" id="showlabels"
              onclick="storeVal('labels', this.checked); wt_showLabels(this.checked)" />
          </td><td>
            <label for="showlabels">Show markers' labels</label>
          </td>
        </tr>
        <tr>
          <td style="text-align:right">
            <input type="checkbox" id="showalts"
              onclick="storeVal('alts', this.checked); wt_showAlts(this.checked)" />
          </td><td>
            <label for="showalts">Show altitudes in labels</label>
          </td>
        </tr>
        <tr>
          <td style="text-align:right">
            <input type="checkbox" id="showwaypoints" checked
              onclick="storeVal('waypoints', this.checked); wt_showWaypoints(this.checked)" />
          </td><td>
            <label for="showwaypoints"><img src="img/icon13noshade.gif" alt="waypoints" title="waypoints"/>&nbsp; Show waypoints</label>
          </td>
        </tr>
        <tr>
          <td style="text-align:right">
            <input type="checkbox" id="showstats"
              onclick="storeVal('stats', this.checked); wt_showStats(this.checked)" />
          </td><td>
            <label for="showstats">Show track statistics</label>
          </td>
        </tr>
      </table>
    </div>

    <div class="options-box" id="tools-box" onkeydown='check_for_escape(event, "tools-box")' style="z-index:10;">
      <table class="box-table">
        <tr>
          <th>Tools</th>
          <th><a href="javascript:close_popup('tools-box')"><img src="img/close.gif" alt="Cancel and Close" title="Cancel and Close" style="border: 0px"/></a></th>
        </tr>
        <tr>
          <form onsubmit="wt_prune(this.prunedist.value); return false">
            <td>
              <input type="submit" value="Compact" />
            </td><td>
              Delete track points keeping track within a
              <input name="prunedist" type="text" size="3" value="5"/>
              meters wide band (increase value to reduce file size)<br>
              Current track has <span id="nbpoints"></span> tracks points.
            </td>
          </form>
        </tr>
        <tr>
          <td>
            <input type="submit" value="Flatten" onclick="wt_altRemoveAll()"/>
          </td><td>
            Remove altitude information from all points
          </td>
        </tr>
        <tr>
          <td>
            <input type="submit" value="Elevate"  onclick="wt_altComputeAll()" />
          </td><td>
            Compute altitude information for up to 10 points of your track,<br>
            overwriting any existing altitude you may have entered.
          </td>
        </tr>
        <tr>
          <td>
            <input type="submit" value="Revert"  onclick="wt_revert()" />
          </td><td>
            Reverts the track: the start becomes the end,<br>
            and the end becomes the start.
          </td>
        </tr>
      </table>
    </div>

    <div class="options-box" id="load-box" onkeydown='check_for_escape(event, "load-box")' style="z-index:10;">
      <table class="box-table">
        <tr>
          <th>Load Options</th>
          <th><a href="javascript:close_popup('load-box')"><img src="img/close.gif" alt="Cancel and Close" title="Cancel and Close" style="border: 0px"/></a></th>
        </tr>
        <tr>
          <form onsubmit="wt_loadGPX(this.url.value, true); return false;">
            <td>
              <input type="submit" value="Load GPX from URL:" />
            </td><td>
              <input id="gpxurl" type="text" size="30" name="url" placeholder="http://..." />
            </td>
          </form>
        </tr>
        <tr>
          <form id="upform" enctype="multipart/form-data" method="post">
            <td>
              <input name="gpxupload" type="submit" value="Load GPX from file:"
                     onclick="return wt_check_fileupload(document.getElementById('upform'));" />
            </td><td>
              <input type="file" size="20" name="gpxfile" id="gpxfile" style="width:100%"
                     onchange="if (wt_check_fileupload(document.getElementById('upform'))) this.form.submit()" />
              <input type="hidden" name="markers" value="" />
              <input type="hidden" name="labels" value="" />
              <input type="hidden" name="alts" value="" />
            </td>
          </form>
        </tr>
        <tr>
          <td style="vertical-align:top;">
            <select id="load_list" size="1" onChange="load_tracks()">
<%
  if (isLoggedIn) {
%>
              <option selected>Your saved track:</option>
              <option>Public tracks:</option>
<% } else {
%>
              <option disabled>Sign in to have your own</option>
              <option selected>Public tracks:</option>
<% } %>
            </select>

          </td><td>
            <input type='text' id='track-filter' size='30' onkeyup='return filterTracks(event, this.value)' placeholder="Search by name">
        </tr>
        <tr>
          <td colspan="2">
            <span id="usertracks-span"><img src='img/processing.gif'></span>
          </td>
        </tr>
      </table>
    </div>


    <div class="options-box" id="save-box" onkeydown='check_for_escape(event, "save-box")'>
      <table class="box-table">
        <tr>
          <th>Save Options</th>
          <th><a href="javascript:close_popup('save-box')"><img src="img/close.gif"
               alt="Cancel and Close" title="Cancel and Close" style="border: 0px"/></a></th>
        </tr>
        <tr>
          <td>Track Name</td>
          <td><input type="text" size="40" id="trackname" onkeypress="return clickOnEnter(event,'savebutton')" placeholder="Enter track name"/></td>
        </tr>
        <tr>
          <td align="right"><input type="checkbox" id="savealt"/></td>
          <td>Save intermediate computed altitudes?</td>
        </tr>
        <tr>
          <td align="right"><input type="checkbox" id="savetime"/></td>
          <td>Save computed timings?</td>
        </tr>
        <tr>
          <td align="right"><input type="checkbox" id="asroute"/></td>
          <td>Use GPX route instead of track?</td>
        </tr>
        <tr>
          <td align="right"><input type="checkbox" id="nometadata" onclick="isNoMetadata(this.checked)"/></td>
          <td>Don't save metadata</td>
        </tr>
<%
  if (isLoggedIn) {
%>
        <tr>
          <td align="right"><input type="checkbox" id="overwrite" /></td>
          <td>Overwrite existing track with same name</td>
        </tr>
<% } %>
        <tr>
          <input type='hidden' id='savetype' value="" />
          <form target="_blank" action="savegpx.jsp" method="post" onSubmit="return wt_doSave()" rel="nofollow">
            <td colspan="2">
              <input type='hidden' id='savedname' name='savedname' value='' />
              <input type="submit" id="savebutton" name="action" value="Download" onclick="document.getElementById('savetype').value='file'"/>
              <input type='hidden' id='id' name='id' value="" />
<%
  if (isLoggedIn) {
%>
              <input id="serversave" type='submit' name='action' value='Save' onclick="document.getElementById('savetype').value='server'"/>
              <input id="servercopy" type='submit' name='action' value='Save a copy' onclick="document.getElementById('savetype').value='copy'"/>
              Visibility :
               <select id="sharemode" name="sharemode" size="1">
                  <option value="<%=wtracks.GPX.SHARED_PRIVATE%>">Private</option>
                  <option value="<%=wtracks.GPX.SHARED_LINK%>">Shareable</option>
                  <option value="<%=wtracks.GPX.SHARED_PUBLIC%>">Public</option>
                </select>
<% } else { %>
              (Sign in to save on this server)
<% } %>
              <textarea name="gpxarea" class="hidden"
                        id="gpxarea" readonly rows="20" cols="80"><%
   boolean isFileUploaded = includeUploadedFile(request, response, out);
%></textarea>
            </td>
          </form>
        </tr>
      </table>
    </div>

    <div class="options-box" id="donate-box" onkeydown='check_for_escape(event, "donate-box")' style="z-index:10;">
      <table class="box-table">
        <tr>
          <th>Donate</th>
          <th><a href="javascript:close_popup('donate-box')"><img src="img/close.gif" alt="Cancel and Close" title="Cancel and Close" style="border: 0px"/></a></th>
        </tr>
        <tr>
          <td colspan="2">
            <h1>Help WTracks!</h1>
             <p>Please support WTracks by contributing to development and hosting costs:</p>
              <a href="<%=donate_link%>" target="_blank"><img src="img/donate-paypal.png" /></a>
             <p>Thanks to all donators!</p>
          </td>
        </tr>
      </table>
    </div>

    <div class="options-box" id="about-box" onkeydown='check_for_escape(event, "about-box")' style="z-index:10;">
      <table class="box-table">
        <tr>
          <th>About</th>
          <th><a href="javascript:close_popup('about-box')"><img src="img/close.gif" alt="Close" title="Close" style="border: 0px"/></a></th>
        </tr>
        <tr>
          <td colspan="2">
            <h1>WTracks <img src="/img/favicon.ico" alt="logo"></h1>
            <div>
              <a href="http://creativecommons.org/licenses/by/2.0/fr/deed.en_US"><img src="https://licensebuttons.net/l/by/2.0/fr/80x15.png" border=0></a>
              <a href="#" onclick="doEmail2('gmail.com','Olivier.Potonniee','?subject=WTracks'); return false">Olivier Potonni&eacute;e</a>
              - <a href="html/privacy.html" target="_blank">Privacy Policy</a>
            </div>
            <div>
              This service is provided as is, with no guarantee.
            </div>
            <div>
              This is an open source project, you may see full code and contribute through our <a href="https://github.com/opoto/wtracks.app">GitHub project</a>
            </div>
            <div>
              Share the word:&nbsp;
              <a class="share-on-link share-on-twitter" target="blank" href="https://twitter.com/intent/tweet?text=WTracks online GPX editor&amp;url=<%= appUrl %>">Twitter</a>

              <a class="share-on-link share-on-facebook" target="blank"  href="https://www.facebook.com/sharer/sharer.php?u=<%= appUrl %>">Facebook</a>

              <a class="share-on-link share-on-googleplus" target="blank"  href="https://plus.google.com/share?url=<%= appUrl %>">Google+</a>
            </div>
          </td>
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

  var isMobile = (/iphone|ipod|android|blackberry|mini|windows\sce|palm/i.test(navigator.userAgent.toLowerCase()));

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

  var ROUNDTRIP_IMG = "<img src='img/roundtrip.png' alt='Round Trip' title='Round Trip'>";
  var ONEWAY_IMG = "<img src='img/oneway.png' alt='One Way' title='One Way'>";
  var WTRACKS = "WTracks - Online GPX track editor"
  var NEW_TRACK_NAME = "New Track"

  //  wpt icon
  var wp_icon = new google.maps.MarkerImage("img/icon13.png") // http://maps.google.com/mapfiles/kml/pal2/
  var wp_icon_shadow = new google.maps.MarkerImage("img/icon13s.png") // http://maps.google.com/mapfiles/kml/pal2/

  //  wpt icon
  var trkpt_icon = new google.maps.MarkerImage("img/mm_20_red.png");
  var trkpt_icon_shadow = new google.maps.MarkerImage("img/mm_20_shadow.png");

  /*------------ Utility functions -----------*/

  var doLog = true;
  function log(msg) {
    if (doLog && console) {
      console.log(msg);
    }
  }
  var doDebug = getParameterByName("debug") == "true";
  function debug(msg) {
    if (doDebug && console && console.debug) {
      console.debug(msg);
    }
  }

  function getMyIpLocation(defpos) {
    log("Getting location from IP address");
    var geoapi = "https://freegeoip.net/json/?callback=";
    Lokris.AjaxCall(geoapi+"setMyIpLocation", function(res) {
      var script = document.createElement("script");
      script.type = "text/javascript";
      script.innerHTML = res;
      document.body.appendChild(script);
    }, { errorHandler : function() {
      log("failed to locate IP, use last position");
      if (defpos) {
        setLocation(defpos);
      } else {
        log("no saved position, I give up!");
      }
    }});
  }
  function setMyIpLocation(res) {
    setLocation({
      lat: res.latitude,
      lng: res.longitude
    });
  }
  function setLocation(pos) {
    map.setCenter(pos);
    map.setZoom(13);
  }
  function gotoMyLocation(defpos) {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(position) {
        setLocation({
          lat: position.coords.latitude,
          lng: position.coords.longitude
        });
      }, function(err){
        log("Geolococation failed: [" + err.code + "] " + err.message);
        getMyIpLocation(defpos);
      });
    } else {
      getMyIpLocation(defpos);
    }
  }
  function savePosition() {
    var pos = map.getCenter();
    storeVal("poslat",pos.lat());
    storeVal("poslng",pos.lng());
  }
  function saveMapType() {
    storeVal("maptype", map.getMapTypeId());
  }

  function getAltitude(lat, lng) {
    // http://ws.geonames.org/srtm3?lat=<lat>&lng=<lng>
    //"http://ws.geonames.org/srtm3?lat="+lat+"&lng="+lng
    var url = "https://maps.google.com/maps/api/elevation/json?sensor=false&locations="+lat+","+lng

    var request = Lokris.AjaxCall("httpget_proxy.jsp?t=p&u="+escape(url), null, {async: false});
    debug(" status:" + request.status)
    var res = 0
    if ((request.status == 200) && (request.responseText)) {
      debug(" text: " + request.responseText)
      var resp = (JSON && JSON.parse) ? JSON.parse(request.responseText) : MochiKit.Base.evalJSON(request.responseText);
      if (resp.status == "OK") {
        res = Math.round(resp.results[0].elevation)
      }
    }
    return res;
  }

  function setTrackName(name) {
    document.title = WTRACKS + (name ? (" - " + name) : "")
    setElement("trktitle", name)
    trackname = name
  }

  function addTrackLink(gpxURL) {
    name = document.getElementById("trktitle").innerHTML;
    setElement("trktitle", "<a href='?gpx=" + gpxURL + "' rel='nofollow'>" + name + "</a>")
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

  function showAlt(alt) {
    alt = Math.round(alt);
    return alt + "m";
  }

  function showDistance(dist) {
    dist = Math.round(dist);
    if (dist > 10000) {
      return (dist/1000).toFixed(1) + "km";
    } else {
      return dist + "m";
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

  function isChecked(eltId) {
    return document.getElementById(eltId).checked;
  }

  function setChecked(eltId, checked) {
    var elt = document.getElementById(eltId);
    var wereShown = elt.checked;
    elt.checked = checked;
    return wereShown;
  }

  function areMarkersShown() {
    return isChecked("showmarkers");
  }

  function setMarkersShown(shown) {
    return setChecked("showmarkers", shown);
  }

  function areWptsShown() {
    return isChecked("showwaypoints");
  }

  function areLabelsShown() {
    return isChecked("showlabels");
  }

  function areAltsShown() {
    return isChecked("showalts");
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
    return google.maps.geometry.spherical.computeDistanceBetween(this, newLatLng)
  }

  /**
   * Returns the closest distance (2D) of a point to a segment defined by 2 points
   *
   * Adapted from Paul Bourke http://local.wasp.uwa.edu.au/~pbourke/geometry/pointline/
   *
   * @param startLine  First point of the segment
   * @param endLine    Second point of the segment
   * @return The distance
   */
  google.maps.LatLng.prototype.distanceFromLine = function(startLine, endLine) {

    var xDelta = endLine.lng() - startLine.lng();
    var yDelta = endLine.lat() - startLine.lat();

    if ((xDelta == 0) && (yDelta == 0)) {
        // startLine and endLine are the same point, return distance from this point
        return this.distanceFrom(startLine);
    }

    var u = ((this.lng() - startLine.lng()) * xDelta + (this.lat() - startLine.lat()) * yDelta) / (xDelta * xDelta + yDelta * yDelta);

    var closestPoint;
    if (u < 0) {
        closestPoint = startLine;
    } else if (u > 1) {
        closestPoint = endLine;
    } else {
        closestPoint = new google.maps.LatLng(startLine.lat() + u * yDelta, startLine.lng() + u * xDelta);
    }

    return this.distanceFrom(closestPoint);
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

  var current_popup;

  function check_for_escape(e, sPopupID){
    //alert(String.fromCharCode(e.keyCode))
    if (e.keyCode==27) {
      close_current_popup();
      close_popup(sPopupID);
    }
  }

  function close_current_popup() {
    if (current_popup) {
      close_popup(current_popup);
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
    current_popup = false;
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
    current_popup = sID;
  }

  function toggle_menu(){
    var shown = (current_popup == "menu");
    close_current_popup();
    if (!shown) show_popup("menu");
  }

  function toggle_user_box(){
    var shown = (current_popup == "user-box");
    close_current_popup();
    if (!shown) show_popup("user-box");
  }

  function show_box(boxname) {
    close_current_popup();
    show_popup(boxname);
  }

  function show_tools_box(boxname) {
    document.getElementById("nbpoints").innerHTML = trkpts ? trkpts.length : 0;
    show_box("tools-box");
  }

  function show_save_box(){
    if (trackname != NEW_TRACK_NAME) {
      document.getElementById("trackname").value = trackname
    } else {
      document.getElementById("trackname").value = "";
    }
<%
  if (isLoggedIn) {
%>
    var servercopy = document.getElementById("servercopy")
    servercopy.style.display = document.getElementById("id").value ? "inline" : "none";
    document.getElementById("overwrite").checked = false
<%
  }
%>
    close_current_popup();
    show_popup("save-box");
    var obj = document.getElementById("trackname");
    obj.focus();
    setChecked("nometadata", false);
    isNoMetadata(isChecked("nometadata"))
  }

  function info(msg) {
    if (msg) {
      if (current_popup == "info") {
        addElement("message", "<p>"+msg+"</p>");
      } else {
        show_popup("info");
        setElement("message", "<p>"+msg+"</p>");
      }
    } else {
      if (current_popup == "info") {
        setElement("message","");
        close_popup("info");
      };
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
    var ptinfo = "Name: <input type='text' size='10' value='" + htmlEncode(this.Wt_getName())
        + "' onchange='"+ this.wt_arrayname + "[" + this.wt_i + "].wt_setName(this.value)' onkeyup='"
        + this.wt_arrayname + "[" + this.wt_i + "].wt_setName(this.value)'/><br/>";
    ptinfo += "Position: <span id='ppos'>" + this.getPosition().toUrlValue() + "</span><br/>";
    return ptinfo
  }

  google.maps.Marker.prototype.Wpt_showInfo = function(openinfo) {
     current_trkpt = undefined
     info("");
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
    if ((this.wt_manalt != undefined) && (this.wt_autoalt == undefined || !this.wt_autoalt) && areAltsShown()) {
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
    //debug("i=" + i + ", newautoalt=" + newautoalt);
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
    this.wt_gpxelt = function(asroute) { return "wpt" }
    this.wt_relocate = google.maps.Marker.prototype.Wpt_relocate
    this.wt_showInfo = google.maps.Marker.prototype.Wpt_showInfo
    this.wt_alt = google.maps.Marker.prototype.Wpt_alt
    this.wt_altview = google.maps.Marker.prototype.Wpt_altview
    this.wt_areMarkersShown = areWptsShown
    this.wt_setAlt = google.maps.Marker.prototype.Wpt_setAlt

    toPt(this, i)
    this.wt_updateTitle();
  }

  google.maps.Marker.prototype.wt_toGPX = function(savealt, savetime, asroute) {
    var gpx = "<" + this.wt_gpxelt(asroute) + " ";
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
      var time = new Date(new Date().getTime() + (this.wt_mantime*1000))
      gpx += "<time>" + time.toISOString() + "</time>";
    }
    gpx += "</" + this.wt_gpxelt(asroute) + ">\n";
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
    wt_showInfo(undefined, false)
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
    this.wt_gpxelt = function(asroute) { return asroute ? "rtept" : "trkpt" }
    this.wt_relocate = google.maps.Marker.prototype.Trkpt_relocate
    this.wt_showInfo = google.maps.Marker.prototype.Trkpt_showInfo
    this.wt_alt = google.maps.Marker.prototype.Trkpt_alt
    this.wt_altview = google.maps.Marker.prototype.Trkpt_altview
    this.wt_areMarkersShown = areMarkersShown
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

  function new_Trkpt(point, alt, name, updateInfo) {
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
      if (updateInfo) {
        pt.wt_setAlt(false, alt)
      } else {
        pt.Wpt_setAlt(false, alt)
      }
    } else if (updateInfo) {
      wt_updateInfoFrom(pt)
    }
    return pt
  }

  /*------------ Global functions -----------*/


  /**
   * Pruning function
   * It removes points located less then "prunedist" meters from the line between its adjacent points
   */
  function wt_prune(prunedist) {
    try {
      var initlen = trkpts.length // initial number of points
      closeInfoWindow()

      if (initlen > 2) { // no pruning required when 0, 1 or 2 points
        var mindeleted = initlen // mindeleted tracks the smallest deleted point index
        var newpoints = []
        var newtrkpts = []

        // we always keep first point
        newtrkpts.push(trkpts[0])
        newpoints.push(points[0])

        var ptmax = initlen - 1 // max trkpt index
        var ptlast = 0 // mast inserted trakpt index

        for (var i = 1;  i < ptmax; i++) {

          var prev = newtrkpts[newtrkpts.length -1].getPosition()
          var next = trkpts[i+1].getPosition()

          for (var j = i; j > ptlast; j--) {
            var pt = trkpts[j].getPosition()
            var delta = pt.distanceFromLine(prev, next)
            if (delta > prunedist) {
              // removing i loses this pt, keep this trkpt[i]
              trkpts[i].wt_i = newtrkpts.length
              ptlast = i
              newtrkpts.push(trkpts[i])
              newpoints.push(points[i])
              break
            }
          }
          // did we keep i?
          if (ptlast != i) {
            // discard this point
            unmapIt(trkpts[i])
            mindeleted = Math.min(i, mindeleted)
          }
        }

        // we always keep last point
        trkpts[initlen - 1].wt_i = newtrkpts.length
        newtrkpts.push(trkpts[trkpts.length - 1])
        newpoints.push(points[trkpts.length - 1])

        if (mindeleted < initlen) { // we deleted something ?
          var removedpts = (initlen - newtrkpts.length);
          alert("Removed " + removedpts + " points out of " + initlen + " (" + Math.round((removedpts / initlen) * 100) + "%)")
          // switch to new values
          points = newpoints
          trkpts = newtrkpts
          // redraw
          wt_drawPolyline()
          wt_updateInfoFrom(trkpts[mindeleted - 1])
          wt_showInfo(undefined, false)
        }
      }
      close_popup('tools-box')
    } catch (e) { alert(e) }
  }

  function wt_altRemoveAll() {
    closeInfoWindow();
    if (trkpts.length > 0) {
      for (var i = trkpts.length - 1 ; i >= 0 ; i--) {
        trkpts[i].Wpt_setAlt(true)
      }
      wt_updateInfoFrom(trkpts[0])
      wt_showInfo(undefined, false)
    }
    close_popup('tools-box')
  }

  function wt_altComputeAll() {
    closeInfoWindow();
    if (trkpts.length > 0) {
      var inc = Math.round(Math.max(1, trkpts.length/10))
      var i = trkpts.length - 1
      while (i >= 0) {
        var ptpos = trkpts[i].getPosition()
        trkpts[i].Wpt_setAlt(false, getAltitude(ptpos.lat(), ptpos.lng()));
        if (i==0) {
          break; // done
        } else {
          i=Math.max(0, i-inc)
        }
      }
      wt_updateInfoFrom(trkpts[0])
      wt_showInfo(undefined, false)
    }
    close_popup('tools-box')
  }

  /**
   * invert track points order
   */
  function wt_revert() {
    try {

      closeInfoWindow()

      var midlen = trkpts.length / 2
      for (var i = 0; i < midlen; i++) {
        var tmppt = trkpts[i]
        trkpts[i] = trkpts[trkpts.length - i -1]
        trkpts[i].wt_i = i
        trkpts[trkpts.length - i -1] = tmppt
        trkpts[trkpts.length - i -1].wt_i = trkpts.length - i -1
      }

      // redraw
      wt_drawPolyline()
      wt_updateInfoFrom(trkpts[0])
      wt_showInfo(undefined, false)

      close_popup('tools-box')
    } catch (e) { alert(e) }
  }

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
    info("");

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

    setElement("distow", "&#8594; " + showDistance(tdist));
    setElement("distrt", "&#8646; " + showDistance(2*tdist));
    setElement("timeow", /*"&#8594; " +*/ showTime(duration));
    setElement("timert", /*"&#8646; " +*/ showTime(duration_rt));
    setElement("altmin", "&#9660; " + showAlt(minalt));
    setElement("altmax", "&#9650; " + showAlt(maxalt));
    setElement("climbing", "+" + showAlt(climbing));
    setElement("descent", "-" + showAlt(descent));

    if (marker) marker.wt_showInfo(openinfo)

  }


  function wt_toGPX(savealt, savetime, asroute, nometadata) {
    var gpx = '<\?xml version="1.0" encoding="ISO-8859-1" standalone="no" \?>\n';
    gpx += '<gpx creator="WTracks" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.topografix.com/GPX/1/1" version="1.1" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">\n';
    if (!nometadata) {
      gpx += "<metadata>\n"
      gpx += "  <name>" + trackname + "</name>\n"
      gpx += "  <desc></desc>\n"
      gpx += "  <author><name>" + WTRACKS + "</name></author>\n"
      gpx += '  <link href="<%=appUrl%>">\n'
      gpx += "    <text>WTracks</text>\n"
      gpx += "    <type>text/html</type>\n"
      gpx += "  </link>\n"
      var now = new Date();
      gpx += "  <time>" + now.toISOString() + "</time>\n";
      var sw = map.getBounds().getSouthWest();
      var ne = map.getBounds().getNorthEast();
      gpx += '<bounds minlat="' + Math.min( sw.lat(), ne.lat()) + '" minlon="' + Math.min( sw.lng(), ne.lng()) + '" maxlat="' + Math.max( sw.lat(), ne.lat()) + '" maxlon="'+ Math.max( sw.lng(), ne.lng()) + '"/>';
      gpx += "</metadata>\n"
    }

    var i = 0;
    while (i < wpts.length) {
      gpx += "  " + wpts[i].wt_toGPX(savealt, savetime, asroute);
      i++;
    }
    var xmlname = "<name>" + trackname + "</name>"
    if (asroute) {
      gpx += "<rte>" + xmlname + "\n";
    } else {
      gpx += "<trk>" + xmlname + "<trkseg>\n";
    }
    i = 0;
    while (i < trkpts.length) {
      gpx += "  " + trkpts[i].wt_toGPX(savealt, savetime, asroute);
      i++;
    }
    if (asroute) {
      gpx += "</rte></gpx>\n";
    } else {
      gpx += "</trkseg></trk></gpx>\n";
    }
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
    setTrackName(NEW_TRACK_NAME)
    document.getElementById("id").value = "";
  }


  function wt_loadGPX(filename, link) {
    if (!filename || filename === "") return;
    close_popup('load-box');
    //info("loading " + filename + "...<br>");
    info("<img src='img/processing.gif'> Loading...");
    Lokris.AjaxCall("httpget_proxy.jsp?t=x&u=" + filename, function(res) {
        if (wt_importGPX((new XMLSerializer()).serializeToString(res)) && link) {
          addTrackLink(filename);
        }
      }, {
        errorHandler : function(res) {
            info("");
            info("<img src='img/delete.gif'> FAILED: " + res.responseText);
          }
      });
  }

  function wt_loadUserGPX(trackid) {
    close_popup('load-box');
    //info("loading " + filename + "...<br>");
    info("<img src='img/processing.gif'> Loading...");
    Lokris.AjaxCall("usertracks.jsp?id=" + trackid, function(res) {
        wt_importGPX(res);
        document.getElementById("id").value = trackid;
      }, {
        errorHandler : function(res) {
            info("");
            info("<img src='img/delete.gif'> FAILED: " + res.responseText);
          }
      });
  }

  function wt_importPoints(xmlpts, is_trk) {
    if (is_trk && (xmlpts.length > 500)) {
      alert("Tracks contains " + xmlpts.length + " points, they are hidden to avoid degrading performance.\nUse Tools/Compact to reduce number of points")
      setMarkersShown(false)
    }
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
        new_Trkpt(point, ele, name, false)
      } else {
        new_Wpt(point, ele, name)
      }
    }

    if (is_trk && (trkpts.length > 0)) wt_updateInfoFrom(trkpts[0])
  }

  function wt_importGPX(gpxinput) {
      wt_clear();
      if (!gpxinput) {
        info("Failed to read file<br>")
        return
      }
      info("Importing... <br>");
      var xml
      if (gpxinput.firstChild) {
        xml = gpxinput;
      } else {
        xml = xmlParse(gpxinput);
      }
      var gpx = xml ? xml.getElementsByTagName("gpx") : undefined
      //debug("gpxinput:<textarea width='40' height='20'>" + gpxinput + "</textarea>")
      debug("xml:" + xml)
      if (!xml.documentElement || !gpx || (gpx.length == 0)) {
        info("The file is not in gpx format<br>")
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
        if (pts && pts.length > 0) {
          // there are track points
          wt_importPoints(pts, true);
        } else {
          // no track point, look for route points
          pts = gpx.getElementsByTagName("rtept");
          if (pts) wt_importPoints(pts, true);
        }
        pts = gpx.getElementsByTagName("wpt");
        if (pts) wt_importPoints(pts, false);
        var center = new google.maps.LatLng(0,0)
        var zoom = 10
        if (bounds && bounds.length > 0) {
          //debug(bounds.length)
          var sw = new google.maps.LatLng(parseFloat(bounds[0].getAttribute("minlat")),
                               parseFloat(bounds[0].getAttribute("minlon")))
          var ne = new google.maps.LatLng(parseFloat(bounds[0].getAttribute("maxlat")),
                               parseFloat(bounds[0].getAttribute("maxlon")))
          var mapbounds = new google.maps.LatLngBounds(sw, ne)
          map.fitBounds(mapbounds)
          map.setZoom(map.getZoom()+1)
        } else {
          // compute bounds to include all trackpoints and waypoints
          var mapbounds = new google.maps.LatLngBounds();
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
          map.fitBounds(mapbounds)
        }
        if (trkpts && trkpts.length > 0) {
          var pt = trkpts[trkpts.length - 1];
          wt_drawPolyline();
          wt_showInfo(pt, true);
        }
        info("");
        return true;
      } else {
        info("Can't read GPX input file");
        return false;
      }
  }

    var QueryString = function () {
    // This function is anonymous, is executed immediately and
    // the return value is assigned to QueryString!
    var query_string = {};
    var query = window.location.search.substring(1);
    var vars = query.split("&");
    for (var i=0;i<vars.length;i++) {
      var pair = vars[i].split("=");
          // If first entry with this name
      if (typeof query_string[pair[0]] === "undefined") {
        query_string[pair[0]] = decodeURIComponent(pair[1]);
          // If second entry with this name
      } else if (typeof query_string[pair[0]] === "string") {
        var arr = [ query_string[pair[0]],decodeURIComponent(pair[1]) ];
        query_string[pair[0]] = arr;
          // If third or later entry with this name
      } else {
        query_string[pair[0]].push(decodeURIComponent(pair[1]));
      }
    }
      return query_string;
  }();

  function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
    return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
  }

  function storeVal(name, val) {
    //log("store " + name + "=" + val);
    if (isChecked("remember")) {
      var store = window.localStorage;
      if (store) {
        if (val === "") {
          store.removeItem(name);
        } else {
          store.setItem(name, val);
        }
      }
    }
  }
  function getVal(name) {
    var store = window.localStorage;
    if (store) {
      return store.getItem(name);
    }
    return undefined;
  }

  function mustShow(name, def) {
    // default
    var doShow = def;
    var queryShow = getParameterByName(name);
    if (queryShow) {
        doShow = (queryShow == "true");
    } else {
      var stored = getVal(name);
      if (stored) {
        doShow = (stored == "true");
      }
    }
    setChecked("show"+name,doShow);
    return doShow;
  }


  function remember() {
    if (isChecked("remember")) {
      if (confirm("For your convenience, your display settings and current location will be stored in your browser (not on server) for future visits.\nConfirm?")) {
        storeVal("remember","true");
        saveMapType();
        savePosition();
        storeVal("alts",isChecked("showalts"));
        storeVal("labels",isChecked("showlabels"));
        storeVal("markers",isChecked("showmarkers"));
        storeVal("waypoints",isChecked("showwaypoints"));
        storeVal("stats",isChecked("showstats"));
      } else {
        setChecked("remember", false);
      }
    } else {
      if (confirm("This will delete all your WTracks preferences from this browser.\nConfirm?")) {
        setChecked("remember", true);
        storeVal("alts","");
        storeVal("labels","");
        storeVal("markers","");
        storeVal("waypoints","");
        storeVal("stats","");
        storeVal("maptype","");
        storeVal("poslat","");
        storeVal("poslng","");
        storeVal("remember","");
        setChecked("remember", false);
      } else {
        setChecked("remember", true);
      }
    }
    close_popup('menu');
  }


  function initDisplay() {
    if (getVal("remember") == "true") {
      setChecked("remember", true);
    } else if (!window.localStorage) {
      document.getElementById("liRemember").style.display = "none";
    }
    wt_showTrkMarkers(mustShow("markers", true));
    wt_showLabels(mustShow("labels", true));
    wt_showAlts(mustShow("alts", false));
    wt_showWaypoints(mustShow("waypoints", true));

    wt_showStats(mustShow("stats", true));
<%
    if (showDonatePopup) {
      out.println("    show_donate_box();");
    }
%>

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

  function wt_showAlts(show) {
    //closeInfoWindow();
    var i = 0;
    while (i < trkpts.length) {
      trkpts[i].wt_updateTitle();
      i++;
    }
    i = 0;
    while (i < wpts.length) {
      wpts[i].wt_updateTitle();
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
          setLocation(geo.location);
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

  function wt_showStats(show) {
    var footer = document.getElementById("footer");
    footer.style.display = show ? "table" : "none";
  }

  function wt_toggleMenu() {
    var menu = document.getElementById("menu");
    var isHidden = menu.style.display == "none";
    menu.style.display = isHidden ? "block" : "none";
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
    // google refesh 2013: https://developers.google.com/maps/documentation/javascript/basics?utm_source=welovemapsdevelopers&utm_campaign=blog-visualrefresh#EnableVisualRefresh
    //google.maps.visualRefresh = true;

    info("<img src='img/processing.gif'> Initializing...");

    var mapType = getVal("maptype");
    if (!mapType) {
      mapType = google.maps.MapTypeId.HYBRID;
    }
    var mapDiv = document.getElementById("map")
    var mapOptions = {
      zoom: 3,
      center: new google.maps.LatLng(0,0),
      mapTypeId: mapType,
      scrollwheel: true,
      disableDoubleClickZoom: isMobile // we suppose mobile=>touch, hence pinch and zoom instead, dblclick is then used to add points
    }
    map = new google.maps.Map(mapDiv, mapOptions);
    //cluster = new MarkerClusterer(map, [], {maxZoom:13, zoomOnClick: false});


    //----- Stop page scrolling if wheel over map ----
    google.maps.event.addDomListener(mapDiv, "DOMMouseScroll", wheelevent);
    mapDiv.onmousewheel = wheelevent;

    geocoder = new google.maps.Geocoder();

    // speed profiles = pairs of <slope, meters per second>

    speed_profiles.push(new SpeedProfile("Walk / Hike",
    [ [-35, 0.4722], [-25, 0.555], [-20, 0.6944], [-14, 0.8333], [-12, 0.9722],
      [-10, 1.1111], [-8, 1.1944], [-6, 1.25], [-5, 1.2638], [-3, 1.25],
      [2, 1.1111], [6, 0.9722], [10, 0.8333], [15, 0.6944], [19, 0.5555],
      [26, 0.4166], [38, 0.2777] ] ))

    speed_profiles.push(new SpeedProfile("Run",
    [ [-16, (12.4/3.6)], [-14,(12.8/3.6)], [-11,(13.4/3.6)], [-8,(12.8/3.6)],
      [-5,(12.4/3.6)], [0,(11.8/3.6)], [9,(9/3.6)], [15,(7.8/3.6)] ] ))

    speed_profiles.push(new SpeedProfile("Bike (road)",
    [ [-6, 13.8888], [-4, 11.1111], [-2, 8.8888], [0, 7.5], [2, 6.1111],
      [4, (16/3.6)], [6, (11/3.6)] ] ))

    speed_profiles.push(new SpeedProfile("Bike (mountain)", [ [0, 3.33] ]));

    speed_profiles.push(new SpeedProfile("Swim", [ [0, 0.77] ]));

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
    var addPointHandler = function(event) {
      var pt = new_Trkpt(event.latLng, undefined, undefined, true);
      wt_drawPolyline();
      wt_showInfo(undefined, false);
    }
    google.maps.event.addListener(map, isMobile ? "dblclick" : "rightclick", addPointHandler);

    // map type listener
    map.addListener('maptypeid_changed', function() {
      saveMapType();
    });

    // left click: close info window
    google.maps.event.addListener(map, "click", function(event) {
      closeInfoWindow()
      close_current_popup();
    })

<%
if (isFileUploaded) {
    out.println("    info('Uploaded file<br>')");
%>
    wt_importGPX(document.getElementById('gpxarea').value, false);
<%
} else {
%>

    var trackid="<%= ((request.getParameter("id") == null) ? "" : request.getParameter("id")) %>";
    var gpxLink = false;
    if (trackid.length>1) {
      wt_loadUserGPX(escape(trackid));
    } else {
      var gpxurl="<%= ((request.getParameter("gpx") == null) ? "" : request.getParameter("gpx")) %>";
      if (gpxurl.length>1) {
        debug(gpxurl);
        //document.getElementById("showmarkers").checked = false;
        gpxLink = true;
        wt_loadGPX(gpxurl, gpxLink);
      } else {
        // center on current position
        clear_track();
        var vlat = getVal("poslat");
        var vlng = getVal("poslng");
        var defpos;
        if (vlat && vlng) {
          defpos = {
            lat: Number.parseFloat(vlat),
            lng: Number.parseFloat(vlng)
          };
        }
        gotoMyLocation(defpos);
      }
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
    form.markers.value = document.getElementById('showmarkers').checked;
    form.labels.value = document.getElementById('showlabels').checked;
    form.alts.value = document.getElementById('showalts').checked;
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

  function postEncoded(str) {
    return encodeURIComponent(str).replace(/[!'()*]/g, function(c) {
      return '%' + c.charCodeAt(0).toString(16);
    });
  }

  function wt_doSave() {
    var name = document.getElementById("trackname").value.trim();
    if (name === "") {
      alert("Track name cannot be empty");
      document.getElementById("trackname").focus();
      return false;
    }
    close_current_popup();
    setTrackName(name);
    document.getElementById("savedname").value = htmlEncode(name, false, 0)
    var savealt = document.getElementById("savealt").checked
    var savetime = document.getElementById("savetime").checked
    var nometadata = document.getElementById("nometadata").checked
    var asroute = document.getElementById("asroute").checked
    document.getElementById("gpxarea").value = wt_toGPX(savealt, savetime, asroute, nometadata)

    var savetype = document.getElementById('savetype').value
    var id = document.getElementById("id").value
    if (savetype === "copy") {
      id = ""
      savetype = "server"
    }
    if (savetype === "server") {
      info("<img src='img/processing.gif'> Saving...");
      var overwrite = document.getElementById("overwrite").checked  ? "true" : "false";
      var postdata = "savedname=" + postEncoded(htmlEncode(name, false, 0)) + "&overwrite=" + overwrite + "&id=" + postEncoded(id) + "&sharemode=" + document.getElementById("sharemode").value + "&gpxarea=" + postEncoded(document.getElementById("gpxarea").value);
      //info(postdata);
      Lokris.AjaxCall("savegpx.jsp", function(res) {
        info("");
        document.getElementById("id").value = res.trim();
      }, {
        method: "POST",
        postBody: postdata,
        errorHandler : function(res) {
          info("");
          info("<img src='img/delete.gif'> FAILED: " + res.responseText);
        }
      });
      info("Sent!");
      return false;
    }
  }

  function isNoMetadata(ischecked) {
    var ssbut = document.getElementById("serversave")
    if (ssbut) {
      ssbut.disabled = ischecked;
    }
  }

  function clickOnEnter(e,toClick) {
    var key=e.keyCode || e.which;
    if (key==13){
      document.getElementById(toClick).click()
	  return false
    }
	  return true
  }

  function filterTracks(e, filter) {
    //console.log("filter: " + filter);
    var entries = document.getElementsByClassName("atrackentry");
    var re = new RegExp(htmlEncode(filter.toLowerCase()));
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i];
      var name = entry.getAttribute("name");
      var display = "none";
      if (re.test(name.toLowerCase())) {
        display = "block";
      }
      entry.setAttribute("style", "display:"+display)
    }
	  return true
  }

  function show_user_tracks(res) {
    document.getElementById("usertracks-span").innerHTML = res;
    document.getElementById("track-filter").style.display = "block"
  }

  function load_tracks() {
    document.getElementById("usertracks-span").innerHTML = "<img src='img/processing.gif'>";
    document.getElementById("track-filter").value = "";
    document.getElementById("track-filter").style.display = "none"
    // "Your tracks" or "Public" ?
    var scope = (document.getElementById("load_list").selectedIndex==0) ? "me" : "all"
    Lokris.AjaxCall("usertracks.jsp", show_user_tracks,
      { method: "POST",
        postBody: "scope="+scope
      });
  }

  function delete_track(name, id) {
    if (confirm("Delete track '" + htmlDecode(name) + "'?")) {
      Lokris.AjaxCall("savegpx.jsp",  function(res) {
          var div = document.getElementById('div-'+id);
          if (div) {
              div.parentNode.removeChild(div);
          }
        },
        { method: "POST",
          postBody: "action=Delete&id="+id,
          errorHandler : function(res) {
            alert("FAILED!");
          }
        }
      );
    }
  }

  function show_load_box(){
    load_tracks();
    close_current_popup();
    show_popup("load-box");
    // dont't focus for mobile: it displays keyboard
    //var obj = document.getElementById("gpxurl");
    //obj.focus();
  }

  function clear_track() {
    wt_clear();
    wt_clear_trackinfo();
    info('');
    close_popup("menu");
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
    //debug(repr(ds))

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
    close_current_popup();
    show_popup("graph-box")
  }

  initDisplay();

    //]]>
    </script>

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

</html>
