<%@ page import="javax.servlet.http.HttpServletResponse, java.io.*, java.net.URL" %>
<%!
  void includeFile(HttpServletResponse response, String contentType, String url) {
    OutputStream o = null;
    try {
      response.setContentType(contentType);
      o = response.getOutputStream();
      InputStream is = new URL(url).openStream();
      byte[] buf = new byte[32 * 1024]; // 32k buffer
      int nRead = 0;
      while( (nRead=is.read(buf)) != -1 ) {
          o.write(buf, 0, nRead);
      }
    } catch (Exception e) {
    } finally {
      if (o!=null) {
        try {
          o.flush();
          o.close(); // *important* to ensure no more jsp output
        } catch (Exception e2) {}
      }
    }
    return; 
  }
%>