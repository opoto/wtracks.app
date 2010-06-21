<%@ include file="includeFile.jsp" %>
<%
  includeFile(response, "text/xml", request.getQueryString());
%>

