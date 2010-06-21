<%@ page import="java.util.*, java.io.*, java.net.*" %>
<%
  String host = request.getServerName();
%>
<%@ include file="config.jsp" %>
<%@ include file="userid.jsp" %>
<%!
  String get_json_openid(String token, String apiKey) {
    StringBuilder res = new StringBuilder();
    try {
      URL oid = new URL("https://rpxnow.com/api/v2/auth_info?token=" + token + "&apiKey=" + apiKey);
      BufferedReader in = new BufferedReader(
                                new InputStreamReader(
                                oid.openStream()));
      String inputLine;
      while ((inputLine = in.readLine()) != null) {
        res.append(inputLine);
      }
      in.close();
    } catch (Exception e) {
      System.err.println("Failed to read RPX OpenID: " + e);
    }
    return res.toString();
  }

%>
<%
  String error_msg = "";
  String redirect = request.getParameter("goto");

  String action = request.getParameter("action");
  String token = request.getParameter("token");

  String openID = getUserID(session);

  System.out.println("token: " + token);
  System.out.println("openID: " + openID);

  if ("logout".equals(action)) {
    clearUserID(session);
    response.sendRedirect(redirect);
  } else if (!"".equals(token)) {

    // just logged in
    // POST token and apiKey to: https://rpxnow.com/api/v2/auth_info
    String jsonoid = get_json_openid(token, rpxnow_key);
    if (jsonoid.length() > 0) {
      setUserID(session, jsonoid);
      response.sendRedirect(redirect);
    } else  {
      out.println("Error: failed get auth info for token "+token+"<br>");
      //echo $php_errormsg;
    }

  } else {
%>
<html>
<head>
<title>Login</title>
</head>
<body>
<%
    if (openID != null) {
%>
You're logged in as 
<script>
   openID = <%= openID %>
   document.write(openID.profile.displayName);
</script>
<br>
<%
    } else {
      out.println("Nothing to see here");
    }
    out.println("</body></html>");
  }
%>
