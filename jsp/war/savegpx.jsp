<%@ page import="java.util.*, java.io.*, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager, javax.jdo.Query" %><%@ include file="userid.jsp" %>
<%!
  void log(Exception ex, String msg, String action, String oid, String trackname) {
    System.err.println("Exception: " + ex);
    System.err.println(msg);
    System.err.println("action: " + action);
    System.err.println("oid: " + oid);
    System.err.println("trackname: " + trackname);
  }
%>
<%

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

  String query = null;
  PersistenceManager pm = null;
  try {
    query = "checking authroization";
    int sharedMode = Integer.parseInt(request.getParameter("sharemode"));

    // check oid matches logged user
    if (!isUser(session,oid)) {
      // not authorized
      response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not authorized to save in this user storage place");
      return;
    }

    pm = PMF.get().getPersistenceManager();

    // search for an existing track with this name
    query = "select owner from " + GPX.class.getName() + " where name==qname parameters String qname";
    Query q = pm.newQuery(query);
    List<String> tracks = (List<String>) q.execute(trackname.replaceAll("'", "\\\\'"));
    if (!tracks.isEmpty()) {
      // at most one should exist
      if (!tracks.get(0).equals(oid)) {
        // cannot overwrite someone else's track
        response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "This track name is already used by another user, please use a different track name");
        return;
      }
    }

    query = "creating GPX";
    GPX gpx = new GPX(trackname, oid, gpxdata, sharedMode, new Date());

    pm.makePersistent(gpx);
  } catch (Exception ex) {
    log(ex, query, action, oid, trackname);
  } finally {
    if (pm != null) pm.close();
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
