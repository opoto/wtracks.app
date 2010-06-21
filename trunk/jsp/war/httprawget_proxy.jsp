<%@ include file="includeFile.jsp" %>
<%
  includeFile(response, "text/plain", request.getQueryString());
%>

