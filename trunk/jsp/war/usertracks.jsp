<%@ page import="java.util.*, java.io.*, javax.servlet.jsp.JspWriter, java.net.URLEncoder, java.net.URLDecoder, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager" %><%@ include file="userid.jsp" %><%!

  GPX getTrack(PersistenceManager pm, String name, String oid) {
    String query = "select from " + GPX.class.getName() + " where name=='" + name.replaceAll("'", "\\\\'") + "' && owner=='" + oid + "'";
    System.out.println("get query: " + query);
    List<GPX> tracks = (List<GPX>) pm.newQuery(query).execute();
    if (tracks.isEmpty()) {
      return null;
    }
    return tracks.get(0); // only one should exist
  }

  void listTracks(PersistenceManager pm, JspWriter out, String oid, boolean isUserOwner) throws IOException {
    String query = "select from " + GPX.class.getName(); //  order by saveDate desc
    boolean publicList = oid.equals("*");
    if (publicList) {
      query += " where sharedMode==" + GPX.SHARED_PUBLIC; //  order by saveDate desc
    } else {
      query += " where owner=='" + oid + "'"; //  order by saveDate desc
    }
    System.out.println("list query: " + query);
    List<GPX> tracks = (List<GPX>) pm.newQuery(query).execute();
    for (GPX track : tracks) {
      if (isUserOwner || (track.getSharedMode() == GPX.SHARED_PUBLIC)) {
        //out.println("<option value='" + track.getName() + "'>" + track.getName() + "</option>");
        String name = track.getName();
        String linktxt = name.length() > 50 ? name.substring(0,47) + "..." : name;
	if (!publicList) {
	  out.println("<a href='#' onclick='delete_track(\"" + URLEncoder.encode(name) + "\")' title='Delete this track'><img src='img/delete.gif' title='Delete this track' alt='delete' style='border:0px'></a>&nbsp;");
	}
        out.print("<a href='.?name=" + URLEncoder.encode(name) + "&oid=" + URLEncoder.encode(track.getOwner()) + "' ");
        out.print(" onclick='wt_loadUserGPX(\"" + URLEncoder.encode(name) + "\", \"" + URLEncoder.encode(track.getOwner()) + "\"); return false; ' >");
        out.println(linktxt + "</a>");
        if (track.getSharedMode() == GPX.SHARED_PUBLIC) {
          out.println("<img src='img/share.gif' title='Public - Anyone can see and read this track' alt='public' style='border:0px'>");
        } else if (track.getSharedMode() == GPX.SHARED_LINK) {
          out.println("<img src='img/link.gif' title='Shareable - you can share this link' alt='shareable' style='border:0px'>");
        }
        out.println("<br>");
      }
    }
  }
  
%><%
  String oid = request.getParameter("oid");
  String name = request.getParameter("name");
  String delete = request.getParameter("delete");
  boolean isUserOwner = isUser(session, oid);

  System.out.println("oid: " + oid);
  System.out.println("Logged OpenID: " + getUserID(session));
  System.out.println("name: " + name);
  System.out.println("delete: " + delete);
  
  if (delete != null) {

    // check oid presence
    if (oid == null) {
      response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing oid");
      return;
    }
    // check oid matches logged user
    if (!isUserOwner) {
      // not authorized
      response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not authorized to delete this track");
      return;
    }

    // get track
    PersistenceManager pm = PMF.get().getPersistenceManager();
    GPX track = getTrack(pm, delete, oid);
    if (track == null) {
      response.sendError(HttpServletResponse.SC_NOT_FOUND, "This track does not exist");
      return;
    }

    pm.deletePersistent(track);

    listTracks(pm, out, oid, isUserOwner);

} else if ((oid != null) && (name == null)) {

    // list
    PersistenceManager pm = PMF.get().getPersistenceManager();
    listTracks(pm, out, oid, isUserOwner);
    
} else if ((name != null) && (oid != null)) {

    PersistenceManager pm = PMF.get().getPersistenceManager();
    GPX track = getTrack(pm, name, oid);
    if (track == null) {
      response.sendError(HttpServletResponse.SC_NOT_FOUND, "This track does not exist");
      return;
    }

    // check oid matches logged user
    if ((!isUserOwner) && (track.getSharedMode() == GPX.SHARED_PRIVATE)) {
      // not authorized
      response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not authorized to get this track");
      return;
    }

    response.setContentType("text/xml");
    out.println(track.getGpx());

}
%>
