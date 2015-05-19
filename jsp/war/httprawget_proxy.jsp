<%@ include file="includeFile.jsp" %><%
   String query = request.getQueryString();
   // ignore request with no query string
   if ((query == null) || (query.length() == 0)) {
     return;
   }
  includeFile(response, "text/plain", java.net.URLDecoder.decode(query));
%>