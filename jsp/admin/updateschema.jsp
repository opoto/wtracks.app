<%@ page import="java.util.*, java.io.*, java.lang.Exception, wtracks.GPX, wtracks.PMF, javax.jdo.PersistenceManager" %><%@ include file="userid.jsp" %>
<html><body>
<%

    PersistenceManager pm = PMF.get().getPersistenceManager();
    try {
      String query = "select from " + GPX.class.getName(); //  order by saveDate desc
      System.out.println("update query: " + query);
      List<GPX> tracks = (List<GPX>) pm.newQuery(query).execute();
      for (GPX track : tracks) {
        GPX gpx = new GPX(track.getName(), track.getOwner(), track.getGpx(),
                          track.getSharedMode(),
                          track.getSaveDate());
        pm.makePersistent(gpx);
      }
      out.println("OK");
    } catch (Exception e) {
      out.println(e);
    } finally {
      pm.close();
    }

%>
</body></html>
