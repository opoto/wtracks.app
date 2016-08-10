<%@ include file="includeFile.jsp" %><%
  String ct = request.getParameter("t");
  String url = request.getParameter("u");
  String contentType = null;
  if ("p".equals(ct)) {
    contentType = "text/plain";
  } else if ("x".equals(ct)) {
    contentType = "text/xml";
    url = url.replaceAll(" ", "%20");
  }
  /*  
  System.out.println("contentType="+contentType+".");
  System.out.println("url="+url+".");
  System.out.println("query="+request.getQueryString() +".");
  */
  if ((url == null) || (url.length() == 0) || (contentType == null)) {
    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid request");
    return;
  }
  if (!includeFile(response, contentType, url)) {
    response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Cannot read requested document");
  }
%>