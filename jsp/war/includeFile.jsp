<%@ page import="javax.servlet.http.HttpServletResponse, java.io.*, java.net.URL" %>
<%!

  void transferFile(InputStream is, Writer o) throws IOException {
    try {
      byte[] buf = new byte[8 * 1024]; // 8k buffer
      int nRead = 0;
      boolean bof = true; // beginning of file
      while( (nRead=is.read(buf)) != -1 ) {
          int pos = 0; // by default copy from start of buf
          if (bof) {
            bof = false;
            if ((buf[0] == (byte)0xEF) && (buf[1] == (byte)0xBB)) {
              // this is UTF8 BOM header, skip it
              pos = 3;
            }
          }
          //System.out.println("writing from " + pos + " to " + (nRead - pos));
          o.write(new String(buf, pos, nRead - pos));
      }
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
  }

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
      transferFile(is, o);
    } catch (Exception e) {
      System.err.println("ERROR in includeFile: " + e);
    }
    return; 
  }
%>