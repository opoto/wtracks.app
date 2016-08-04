<%@ page import="java.util.*, java.io.*, javax.servlet.jsp.JspWriter, java.net.URLEncoder, java.net.URLDecoder, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager, javax.jdo.Query, org.apache.commons.lang3.StringEscapeUtils" %><%@ include file="userid.jsp" %><%!

  GPX getTrack(PersistenceManager pm, String name, String oid) {
    String query = "select from " + GPX.class.getName() + " where name==qname && owner==qowner parameters String qname, String qowner";
    Query q = pm.newQuery(query);
    List<GPX> tracks = (List<GPX>) q.execute(name.replaceAll("'", "\\\\'"), oid);
    
    if (tracks.isEmpty()) {
      return null;
    }
    return tracks.get(0); // only one should exist
  }

  void listTracks(PersistenceManager pm, JspWriter out, String oid, boolean isUserOwner, String hostURL) throws IOException {
    String query = "select name, owner, sharedMode from " + GPX.class.getName(); 
    boolean publicList = oid.equals("*");
    Object param;
    if (publicList) {
      query += " where sharedMode==qsharedmode parameters int qsharedmode";
      param = new Integer(GPX.SHARED_PUBLIC); 
    } else {
      query += " where owner==qowner parameters String qowner";
      param = oid; 
    }
    //System.out.println("list query: " + query);
    List<Object[]> tracks = (List<Object[]>) pm.newQuery(query).execute(param);
    for (Object[] track : tracks) {
      String name = (String)track[0];
      String owner = (String)track[1];
      int sharedMode = ((Integer)track[2]).intValue();
      if (isUserOwner || (sharedMode == GPX.SHARED_PUBLIC)) {
        String linktxt = name.length() > 50 ? name.substring(0,47) + "..." : name;
        out.println("<div class='atrackentry' name='" + StringEscapeUtils.escapeXml(name) + "'>");
        if (!publicList) {
          out.println("<a href='#' onclick='delete_track(\"" + URLEncoder.encode(name) + "\")' title='Delete this track'><img src='img/delete.gif' title='Delete this track' alt='delete' style='border:0px'></a>&nbsp;");
        }
        String qparam = "?name=" + URLEncoder.encode(name) + "&oid=" + URLEncoder.encode(owner);
        out.print("<a href='." + qparam + "' ");
        out.print(" onclick='wt_loadUserGPX(\"" + URLEncoder.encode(name) + "\", \"" + URLEncoder.encode(owner) + "\"); return false; ' >");
        out.println(linktxt + "</a>");
        if (sharedMode == GPX.SHARED_PUBLIC) {
          out.println("<img src='img/share.gif' title='Public - Anyone can see and read this track' alt='public' style='border:0px'>");
        } else if (sharedMode == GPX.SHARED_LINK) {
          out.println("<img src='img/link.png' title='Shareable - you can share this link' alt='shareable' style='border:0px'>");
        }
        out.println("<a target='_blank' href='http://chart.apis.google.com/chart?cht=qr&chs=400x400&chld=L&choe=UTF-8&chl="+URLEncoder.encode(hostURL + qparam)+"'><img src='img/qrcode.png' title='Show QRCode' alt='QRCode' style='border:0px'></a>");
        out.println("</div>");
      }
    }
  }
  
%><%
  String oid = request.getParameter("oid");
  String name = request.getParameter("name");
  String delete = request.getParameter("delete");
  String scheme = request.isSecure() ? "https" : "http";
  String hostURL = scheme + "://" + request.getServerName() + "/";
  boolean isUserOwner = isUser(session, oid);
/*
  System.out.println("oid: " + oid);
  System.out.println("Logged UserID: " + getUserID(session));
  System.out.println("name: " + name);
  System.out.println("delete: " + delete);
*/
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

    listTracks(pm, out, oid, isUserOwner, hostURL);

} else if ((oid != null) && (name == null)) {

    // list
    PersistenceManager pm = PMF.get().getPersistenceManager();
    listTracks(pm, out, oid, isUserOwner, hostURL);
    
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
