<%@ page import="java.util.*, java.io.*, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager, javax.jdo.Query" %><%@ include file="userid.jsp" %><%!
  void log(Exception ex, String msg, String action, String id, String name) {
    System.err.println("Exception: " + ex);
    System.err.println(msg);
    System.err.println("action: " + action);
    System.err.println("id: " + id);
    System.err.println("name: " + name);
  }
  void saveError(HttpServletResponse response, String message) throws IOException {
    System.err.println("save error: " + message);
    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, message);
  }
  void saveOK(JspWriter out, String id) throws IOException {
    System.out.println("save ok: " + id);
    out.println(id);
  }
  boolean isNameUsed(PersistenceManager pm, String userID, String name) {
    String query = "select id from " + GPX.class.getName() + " where owner==qowner && name==qname parameters String qowner, String qname";
    List<String> ids = (List<String>) pm.newQuery(query).execute(userID, name);
    return (!ids.isEmpty());
  }
%><%

// ignore non post requests
if (!"POST".equalsIgnoreCase(request.getMethod())) {
  return;
}

String action = request.getParameter("action");
String gpxdata = request.getParameter("gpxarea").replaceAll("\\\"", "\"");
String name = request.getParameter("savedname");
String id = request.getParameter("id");
/*
System.out.println("action: " + action);
System.out.println("id: " + id);
System.out.println("name: " + name);
System.out.println("gpx: " + gpxdata);
*/

if ("Download".equals(action)) {
  response.setContentType("application/octet-stream");
  response.setHeader("Content-disposition", "attachment; filename=\"" + name + ".gpx\"");
  out.print(gpxdata);
} else {
  
  String userID = getUserID(session);
  if ((userID == null) || (userID.length() == 0)) {
    saveError(response, "You must be logged to save on server");
    return;
  }
  
  String query = null;
  PersistenceManager pm = null;
  try {
    int sharedMode = Integer.parseInt(request.getParameter("sharemode"));

    query = "checking previous version";
    pm = PMF.get().getPersistenceManager();
    
    if ((id != null) && (id.length() > 0)) { 
      GPX track = getTrack(session, pm, id);
      if ((track != null) && (isUser(session,track.getOwner()))) {
        if ((!name.equals(track.getName()) && isNameUsed(pm, userID, name))) {
          saveError(response, "You already saved a track with this name, change track name or delete previous one first");
          return;
        }
        // update
        track.setName(name);
        track.setSharedMode(sharedMode);
        track.setGpx(gpxdata);
        track.setSaveDate();
        saveOK(out, id);
        return;
      }
    } 
    
    query = "checking name duplicates";
    if (isNameUsed(pm, userID, name)) {
      saveError(response, "You already saved a track with this name, change track name or delete previous one first");
      return;
    }

    List<String> ids = null;
    do {
      id = newTrackId();
      query = "select id from " + GPX.class.getName() + " where id==qid parameters String qid";
      ids = (List<String>) pm.newQuery(query).execute(id);
    } while (!ids.isEmpty());
    
    query = "creating GPX";
    GPX gpx = new GPX(id, name, userID, gpxdata, sharedMode);
    pm.makePersistent(gpx);
    saveOK(out, id);

  } catch (Exception ex) {
    log(ex, query, action, id, name);
  } finally {
    if (pm != null) pm.close();
  }
}
%>