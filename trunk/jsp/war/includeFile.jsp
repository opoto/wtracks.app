<%@ page import="javax.servlet.http.HttpServletResponse, java.io.*, java.net.URL" %>
<%!
  void includeFile(HttpServletResponse response, String contentType, String url) {
    PrintWriter o = null;
    InputStream is = null;
    try {
      response.setContentType(contentType);
      o = response.getWriter(); // // don't use OutputStream, it causes java.lang.IllegalStateException: STREAM
      if (url.matches("^[a-z]+://.*")) {
        is = new URL(url).openStream();
      } else {
        is = new FileInputStream(url);
      }
      byte[] buf = new byte[32 * 1024]; // 32k buffer
      int nRead = 0;
      while( (nRead=is.read(buf)) != -1 ) {
          o.write(new String(buf, 0, nRead));
      }
    } catch (Exception e) {
      System.err.println("ERROR in includeFile: " + e);
    } finally {
      if (is!=null) {
        try {
          is.close();
        } catch (Exception e2) {}
      }
      if (o!=null) {
        try {
          o.flush();
          o.close(); // *important* to ensure no more jsp output
        } catch (Exception e3) {}
      }
    }
    return; 
  }
%>