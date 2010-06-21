<%@ page import="java.util.*, java.io.*, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager" %>
<%@ include file="userid.jsp" %>
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
} else if ((oid != null) && (oid.length() > 0)) {

  // check oid matches logged user
  if (!isUser(session,oid)) {
    // not authorized
    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not authorized to save in this user storage place");
    return;
  }

  GPX gpx = new GPX(trackname, oid, gpxdata, false, new Date());

  PersistenceManager pm = PMF.get().getPersistenceManager();

  try {
    pm.makePersistent(gpx);
  } finally {
    pm.close();
  }
  out.println("<html><body>\n File saved :)");
%>
    <script type='text/javascript'>self.close()</script>
    </body></html>
<%
} else {
    out.println("<html><body>Invalid request</body></html>");
} 
%>
