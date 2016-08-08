<%@ page import="java.util.*, java.io.*, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager, java.util.logging.Logger" %><%@ include file="userid.jsp" %><%!

  static Logger log = Logger.getLogger("savegpx");

  void log(Exception ex, String msg, String action, String id, String name) {
    log.severe("Exception: " + ex);
    log.severe(msg);
    log.severe("action: " + action);
    log.severe("id: " + id);
    log.severe("name: " + name);
  }
  void saveError(HttpServletResponse response, JspWriter out, String message1, String message2) throws IOException {
    log.warning("save error: " + message1);
    response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
    out.println(message1);
    out.println("<br>" + message2);
  }
  String getTrackIdByName(PersistenceManager pm, String userID, String name) throws Exception {
    String query = "select id from " + GPX.class.getName() + " where owner==qowner && name==qname parameters String qowner, String qname";
    List<String> ids = (List<String>) pm.newQuery(query).execute(userID, name);
    return ids.isEmpty() ? null : ids.get(0);
  }
%><%

// ignore non post requests
if (!"POST".equalsIgnoreCase(request.getMethod())) {
  return;
}

String action = request.getParameter("action");
String gpxdata = request.getParameter("gpxarea").replaceAll("\\\"", "\"");
String name = request.getParameter("savedname").trim();
String id = request.getParameter("id");
boolean overwrite = "true".equals(request.getParameter("overwrite"));
/*
log.info("action: " + action);
log.info("id: " + id);
log.info("name: " + name);
log.info("gpx: " + gpxdata);
*/

if ("Download".equals(action)) {
  response.setContentType("application/octet-stream");
  response.setHeader("Content-disposition", "attachment; filename=\"" + name + ".gpx\"");
  out.print(gpxdata);
} else {

  String userID = getUserID(session);
  if ((userID == null) || (userID.length() == 0)) {
    saveError(response, out, "You must be logged to save on server", "");
    return;
  }
  if ((name == null) || (name.length() == 0)) {
    saveError(response, out, "Track name cannot be empty", "");
    return;
  }

  String query = null;
  PersistenceManager pm = null;
  try {
    int sharedMode = Integer.parseInt(request.getParameter("sharemode"));

    pm = PMF.get().getPersistenceManager();

    GPX track = null;
    boolean isUpdate = false;
    boolean deletePrevious = false;
    
    query = "checking previous track version";
    if ((id != null) && (id.length() > 0)) {
      track = getTrack(session, pm, id);
      if (track != null) {
        if (!isUser(session, track.getOwner())) {
          // no write acces to this track
          track = null;
          id = null;
        } else if (track.getName().equals(name)) {
          // user owns this track, and no name change
          isUpdate = true;
        }
      }
    }

    if (!isUpdate) {
      query = "checking homonymous";
      String homonymousid = getTrackIdByName(pm, userID, name);
      if (homonymousid != null) {
        if (overwrite) {
          if (track != null) {
            // we can remove previous track once we overwrite new one
            deletePrevious = true;
          }
          id = homonymousid;
        } else {
          log.warning("NANE OVERLAP: " + name);
          saveError(response, out, "You already saved a track named: "+ name, "<br>You need to either:<ul><li>use another track name, or</li><li>delete previous track with same name, or</li><li>check 'overwrite' save option</li></ul>");
          return;
        }
      } else if (track == null) {
        List<String> ids = null;
        do {
          // generate random UUID
          id = newTrackId();
          // make sure it is not already used
          query = "select id from " + GPX.class.getName() + " where id==qid parameters String qid";
          ids = (List<String>) pm.newQuery(query).execute(id);
        } while (!ids.isEmpty());
      }
    }

    query = "creating GPX";
    GPX gpx = new GPX(id, name, userID, gpxdata, sharedMode);
    pm.makePersistent(gpx);
    log.info("save ok: " + id);
    out.println(id);

    if (deletePrevious) {
      log.info("deleting deprecated " + track.getId());
      pm.deletePersistent(track);
    }
    
  } catch (Exception ex) {
    log(ex, query, action, id, name);
  } finally {
    if (pm != null) pm.close();
  }
}
%>