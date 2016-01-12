<%
  // compute application url
  String host = request.getServerName();
  int port = request.getServerPort();
  String scheme = request.getScheme();
  boolean isDefaultPort = (request.isSecure() && (port == 443)) || (port == 80);
  String appUrl = scheme + "://" + host;
  if (!isDefaultPort) {
    appUrl += (":" + port);
  }
  String ctxPath = request.getContextPath();
  if (ctxPath.length() == 0) {
    ctxPath = "/";
  }
  appUrl += ctxPath;
%>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset='utf-8'>
    <link rel="shortcut icon" href="img/favicon.ico" />
    <meta http-equiv="x-ua-compatible" content="IE=edge" >
    <META name="keywords" content="GoogleMaps, Map, GPX, GPS, Tracks, Trails, GIS, outdoor">
    <title>About WTracks</title>
    <script src="js/showmail.js" type="text/javascript"></script>
    <style type="text/css">
    body, div, p, td, th {
      font-family:sans-serif;
      font-size: 12pt;
    }
    th {
      vertical-align: middle;
      text-align: right;
      background-color: #ddd;
      padding: 0 5px;
    }
    div {
      margin: 15px;
    }
    #url-syntax {
      border: solid 1px #666;
      border-collapse: collapse;
    }
    #url-syntax th,
    #url-syntax td {
      text-align: left;
      padding: 3px;
      border: solid 1px #666;
    }

    .share-on-link {
      padding:5px 10px;
      color:white
    }
    a.share-on-link {
      text-decoration: none;
    }
    .share-on-link:hover,.share-on-link:active,a.share-on-link:visited {
      color:white
    }
    .share-on-twitter {
      background:#41B7D8
    }
    .share-on-twitter:hover,.share-on-twitter:active {
      background:#279ebf
    }
    .share-on-facebook {
      background:#3B5997
    }
    .share-on-facebook:hover,.share-on-facebook:active {
      background:#2d4372
    }
    .share-on-googleplus {
      background:#D64937
    }
    .share-on-googleplus:hover,.share-on-googleplus:active {
      background:#b53525
    }

    </style>
  </head>
  <body>
    <h1>About WTracks <img src="../img/favicon.ico" alt="logo"></h1>

      <div>
        <a href="http://creativecommons.org/licenses/by/2.0/fr/deed.en_US"><img src="https://licensebuttons.net/l/by/2.0/fr/80x15.png" border=0></a>
        <a href="#" onclick="doEmail2('gmail.com','Olivier.Potonniee','?subject=WTracks'); return false">Olivier Potonni&eacute;e</a>
        - <a href="html/privacy.html">Privacy Policy</a>
      </div>
      <div>
        This is an open source project, you may see full code and contribute through our <a href="https://github.com/opoto/wtracks">GitHub project</a>
      </div>
      <div>
        Share the word:&nbsp;
        <a class="share-on-link share-on-twitter" target="blank" href="https://twitter.com/intent/tweet?text=WTracks online GPX editor&amp;url=<%= appUrl %>">Twitter</a>

        <a class="share-on-link share-on-facebook" target="blank"  href="https://www.facebook.com/sharer/sharer.php?u=<%= appUrl %>">Facebook</a>

        <a class="share-on-link share-on-googleplus" target="blank"  href="https://plus.google.com/share?url=<%= appUrl %>">Google+</a>

      </div>
      <div>
        In order to share a direct link to a specific track with specific display settings, you can use the following URL syntax:
        <p><code><%= appUrl %>[?param1=value1[&amp;param2=value2]...]</code></p>
        Where parameters can be:
        <table id="url-syntax">
          <tr><th>Name</th><th>Value</th><th></th></tr>
          <tr><td>gpx</td><td>URL</td><td>URL of an online GPX file</td></tr>
          <tr><td>markers</td><td>true|false</td><td>Controls track markers display</td></tr>
          <tr><td>labels</td><td>true|false</td><td>Controls marker labels display</td></tr>
          <tr><td>alts</td><td>true|false</td><td>Controls label altitudes display</td></tr>
          <tr><td>waypoints</td><td>true|false</td><td>Controls waypoints display</td></tr>
          <tr><td>stats</td><td>true|false</td><td>Controls statistics display</td></tr>
        </table>
      </div>
  </body>
</html>
