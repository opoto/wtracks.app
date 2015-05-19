<%@ page import="java.util.*, java.io.*, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager" %><%@ include file="userid.jsp" %><%

// ignore non post requests
if (!"POST".equalsIgnoreCase(request.getMethod())) {
  return;
}

String action = request.getParameter("action");
String gpxdata = request.getParameter("gpxarea").replaceAll("\\\"", "\"");
String oid = request.getParameter("oid");
String trackname = request.getParameter("savedname");

//System.out.println("gpx: " + gpxdata);
//System.out.println("trackname: " + trackname);
//System.out.println("oid: " + oid);

if ("Save".equals(action)) {
  response.setContentType("application/octet-stream");
  response.setHeader("Content-disposition", "attachment; filename=\"" + trackname + ".gpx\"");
  out.print(gpxdata);
} else if ((oid != null) && (oid.length() > 0)) {

  int sharedMode = Integer.parseInt(request.getParameter("sharemode"));

  // check oid matches logged user
  if (!isUser(session,oid)) {
    // not authorized
    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not authorized to save in this user storage place");
    return;
  }

  PersistenceManager pm = PMF.get().getPersistenceManager();

  // search for an existing track with this name
  String query = "select from " + GPX.class.getName() + " where name=='" + trackname.replaceAll("'", "\\\\'") + "'";
  List<GPX> tracks = (List<GPX>) pm.newQuery(query).execute();
  if (!tracks.isEmpty()) {
    // at most one should exist
    if (!tracks.get(0).getOwner().equals(oid)) {
      // cannot overwrite someone else's track
      response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "This track name is already used by another user, please use a different track name");
      return;
    }
  }

  GPX gpx = new GPX(trackname, oid, gpxdata, sharedMode, new Date());


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
