<%@ page import="org.apache.commons.codec.binary.Base64, java.util.*, java.io.*, java.lang.Exception" %>
<%!
  String toBase64(String v) {
    return new Base64().encodeToString(v.getBytes());
  }
%>
<%

String action = request.getParameter("action");
String gpxdata = request.getParameter("gpxarea").replaceAll("\\\"", "\"");
String oid = request.getParameter("oid");
String trackname = request.getParameter("savedname");
String host = request.getServerName();

System.out.println("gpx: " + gpxdata);
System.out.println("trackname: " + trackname);
System.out.println("oid: " + oid);

if ("Save".equals(action)) {
  response.setContentType("application/octet-stream");
  response.setHeader("Content-disposition", "attachment; filename=\"" + trackname + ".gpx\"");
  out.print(gpxdata);
} else if (oid.length() > 0) {
  File userdir = new File("tracks/" + toBase64(oid));
  if (! userdir.exists()) {
    userdir.mkdirs();
  }
  String fname = toBase64(trackname);
  String fpath = userdir + "/" + fname + ".gpx";
  if (true/*!file_put_contents($fpath, $gpxdata)*/) {
    out.println("error: failed to save file... NOT IMPLEMENTED");
  } else {
    out.println("<html><body>\n File saved: <a href='http://" + host + "/" + fpath + "'>" + trackname + "</a>");
%>
    <script type='text/javascript'>self.close()</script>
    </body></html>
<%
  }
} else {
    out.println("<html><body>Invalid request</body></html>");
} 
%>
