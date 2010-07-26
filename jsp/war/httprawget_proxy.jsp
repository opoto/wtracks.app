<%@ include file="includeFile.jsp" %><%
  includeFile(response, "text/plain", java.net.URLDecoder.decode(request.getQueryString()));
%>

