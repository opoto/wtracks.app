<%@ page import="java.util.*, java.io.*, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager" %><%@ include file="userid.jsp" %><%
  String oid = request.getParameter("oid");
  String name = request.getParameter("name");
  String delete = request.getParameter("delete");
  boolean isUserOwner = isUser(session, oid);

  System.out.println("oid: " + oid);
  System.out.println("Logged OpenID: " + getUserID(session));
  System.out.println("name: " + name);
  System.out.println("delete: " + delete);
  
  if (delete != null) {
    System.out.println("delete NOT IMPLEMENTED: " + delete);
  } else if ((oid != null) && (name == null)) {

    // list
    PersistenceManager pm = PMF.get().getPersistenceManager();
    String query = "select from " + GPX.class.getName() + " where owner=='" + oid + "'"; //  order by saveDate desc 
    System.out.println("list query: " + query);
    List<GPX> tracks = (List<GPX>) pm.newQuery(query).execute();
    for (GPX track : tracks) {
      if (isUserOwner || track.isPublic()) {
        out.println("<option value='" + track.getName() + "'>" + track.getName() + "</option>");
      }
    }

  } else if ((name != null) && (oid != null)) {

    PersistenceManager pm = PMF.get().getPersistenceManager();
    String query = "select from " + GPX.class.getName() + " where name=='" + name + "' && owner=='" + oid + "'";
    System.out.println("get query: " + query);
    List<GPX> tracks = (List<GPX>) pm.newQuery(query).execute();
    if (tracks.isEmpty()) {
      response.sendError(HttpServletResponse.SC_NOT_FOUND, "This track does not exist");
      return;
    }
    GPX track = tracks.get(0); // only one should exist

    // check oid matches logged user
    if ((!isUserOwner) && (!track.isPublic())) {
      // not authorized
      response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Not authorized to get this track");
      return;
    }

    response.setContentType("text/xml");
    out.println(track.getGpx());

  }
%>
