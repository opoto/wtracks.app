<%@ page import="java.util.*, java.io.*, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager, javax.jdo.Query, java.util.UUID" %><%@ include file="userid.jsp" %>
<html>
  <body>
<%

  int size = -1;
  int left = -1;
  String id = "none";

  PersistenceManager pm = null;
  String query = "";
  Query q;
  List<GPX> tracks;

  try {

/* Create DB */
    String owner = "https://www.google.com/accounts/o8/id?id=myid";
    if ("create".equals(request.getParameter("action"))) {

      pm = PMF.get().getPersistenceManager();

       for (int i = 0; i <10; i++) {
            GPX created = new GPX("Track #" + i, null, owner, "", GPX.SHARED_PUBLIC);
            pm.makePersistent(created);
            //pm.flush();
       }
        pm.close();
      }

/**/

    pm = PMF.get().getPersistenceManager();

    // ignore non post requests
    if ("migrate".equals(request.getParameter("action"))) {
      query = "select from " + GPX.class.getName() ;
     q = pm.newQuery(query);
      tracks = (List<GPX>) q.execute();
      for (GPX track : tracks) {
        if (track.getName() == null) {
            GPX migrated = new GPX(newTrackId(), track.getId(), track.getOwner(), track.getGpx(), track.getSharedMode());
            migrated.setSaveDate(track.getSaveDate());
            pm.makePersistent(migrated);
            pm.flush();
            pm.deletePersistent(track);
            pm.flush();
        }
      }
      pm.close();
      pm = PMF.get().getPersistenceManager();
   }

    query = "select from " + GPX.class.getName() ;
    q = pm.newQuery(query);
    tracks = (List<GPX>) q.execute();
    size = tracks.size();

    /**/
    int limit = 10;
    String pview = request.getParameter("view");
    if (pview != null) try {
      int v = Integer.parseInt(pview);
      limit = v;
    } catch (Exception ex) { ex.printStackTrace(); }
    for (GPX track : tracks) {
      if (--limit < 0) break;
      out.println(track.toString() + "<br/>");
    }
    /**/

    query = "select id from " + GPX.class.getName() + " where name != :qid";
    q = pm.newQuery(query);
    String qid = null;
    tracks = (List<GPX>) q.execute(qid);
    left = size - tracks.size();

  } catch (Exception ex) {
    System.err.println("ERROR in " + query);
    System.err.println(ex);
  } finally {
    if (pm != null) pm.close();
  }
%>
    <p>Number of entries: <%=size%></p>
    <p>Number of entries to migrate: <%=left%></p>
    <p><a href="./newid.jsp?action=migrate">Migrate</a></p>
    <p>Current user: <%=getUser(session)%></p>
    <p>Current userID: <%=getUserID(session)%></p>
    </body>
</html>
