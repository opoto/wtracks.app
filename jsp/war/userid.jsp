<%@ page import="java.util.*, java.io.*, javax.servlet.jsp.JspWriter, java.net.URLEncoder, java.net.URLDecoder, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager, javax.jdo.Query, org.apache.commons.lang3.StringEscapeUtils, javax.servlet.http.HttpSession, org.json.JSONObject, java.util.logging.Logger" %><%!

  static Logger ulog = Logger.getLogger("userid");

  String getUser(HttpSession session) {
    return (String)session.getAttribute("LoginUserID");
  }

  String getUserID(HttpSession session) {
    String u = getUser(session);
    if (u == null) return null;
    // get profile.identifier
    JSONObject jobj = new JSONObject(u);
    String userId = jobj.getJSONObject("profile").getString("identifier");
    return userId;
  }

  String getUserProfileField(JSONObject jobj, String field) {
    try {
      return jobj.getJSONObject("profile").getString(field);
    } catch (Exception ex) {
      return null;
    }
  }

  String getUserName(HttpSession session) {
    String u = getUser(session);
    if (u == null) return null;
    // get profile.displayName
    JSONObject jobj = new JSONObject(u);
    String userId = "";
    userId = getUserProfileField(jobj, "displayName");
    if (userId == null) {
      ulog.info("User has no displayName: " + u);
      userId = getUserProfileField(jobj, "displayName");
      if (userId == null) {
        userId = getUserProfileField(jobj, "providerSpecifier");
        if (userId == null) {
          userId = "Anonymous user";
        } else {
          userId += " user";
        }
      }
    }
    userId = StringEscapeUtils.escapeHtml4(userId);
    return userId;
  }

  void setUser(HttpSession session, String user) {
    session.setAttribute("LoginUserID", user);
  }

  void clearUser(HttpSession session) {
    session.removeAttribute("LoginUserID");
  }

  boolean isUser(HttpSession session, String identifier) {
    String currentUser = getUserID(session);
    if (currentUser == null) {
      return false;
    }
    boolean ok = currentUser.equals(identifier);
    if (!ok) ulog.severe("user mismatch: " + currentUser + " != " + identifier);
    return ok;
  }

  String newTrackId() {
    return UUID.randomUUID().toString();
  }

  GPX getTrack(HttpSession session, PersistenceManager pm, String id) {
    String query = "select from " + GPX.class.getName() + " where id==:qid";
    Query q = pm.newQuery(query);
    List<GPX> tracks = (List<GPX>) q.execute(id);

    if (tracks.isEmpty()) {
      return null;
    }
    GPX track = tracks.get(0); // only one should exist
    // check authorized
    if ((!isUser(session,track.getOwner())) && (track.getSharedMode() == GPX.SHARED_PRIVATE)) {
      return null;
    } else {
      return track;
    }
  }

%>