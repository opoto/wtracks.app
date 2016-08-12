<%@ page import="javax.servlet.http.*, org.apache.commons.fileupload.*, org.apache.commons.fileupload.servlet.ServletFileUpload, org.apache.commons.fileupload.disk.DiskFileItemFactory, java.io.*, java.net.URL" %><%!

  void transferFile(InputStream is, Writer os) throws IOException {
    int total = 0;
    int MAX_LEN = 5000000;
    try {
      byte[] buf = new byte[16 * 1024]; // 16k buffer
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
          os.write(new String(buf, pos, nRead - pos));
          total += (nRead - pos);
      }
    } finally {
      if (total > MAX_LEN) {
        System.err.println("[INFO] Loaded size was: " + total);
      }
    }
  }

  boolean includeFile(HttpServletResponse response, String contentType, String url) {
    PrintWriter os = null;
    InputStream is = null;
    try {
      is = new URL(url).openStream();
      response.setContentType(contentType);
      os = response.getWriter(); // // don't use OutputStream? caused java.lang.IllegalStateException: STREAM
      transferFile(is, os);
      return true; 
    } catch (Exception e) {
      System.err.println("ERROR in includeFile: " + e + "(" + url + ")");
      return false;
    } finally {
      if (is!=null) {
        try {
          is.close();
        } catch (Exception e2) {}
      }
      if (os!=null) {
        try {
          os.flush();
          os.close(); // *important* to ensure no more jsp output
        } catch (Exception e3) {}
      }
    }
  }
  
  boolean includeUploadedFile(HttpServletRequest request, HttpServletResponse response, Writer out) {
    InputStream is = null;
    try {
      if (ServletFileUpload.isMultipartContent(request)){
        ServletFileUpload servletFileUpload = new ServletFileUpload(new DiskFileItemFactory());
        FileItemIterator it = servletFileUpload.getItemIterator(request);
        FileItemStream fileItem = null;
        while (it.hasNext()){
          fileItem = (FileItemStream)it.next();
          if (!fileItem.isFormField()) {
            /*
            String file_name = fileItem.getName();
            System.out.println("reading file: " + file_name);
            */
            is = fileItem.openStream();
            transferFile(is, out);
            return true; 
          }
        }
      }
    } catch (Exception e) {
      System.err.println("ERROR in uploadedFile: " + e);
    } finally {
      if (is!=null) {
        try {
          is.close();
        } catch (Exception e2) {}
      }
    }
    return false;
  }

%>