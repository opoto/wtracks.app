<%@ page import="java.util.*, java.io.*, java.net.*" %>
<%
  String host = request.getServerName();
%>
<%@ include file="config.jsp" %>
<%@ include file="userid.jsp" %>
<%!
  String get_json_userid(String token, String apiKey) {
    StringBuilder res = new StringBuilder();
    try {
      URL uid = new URL("https://rpxnow.com/api/v2/auth_info?token=" + token + "&apiKey=" + apiKey);
      BufferedReader in = new BufferedReader(
                                new InputStreamReader(
                                uid.openStream(), "UTF-8"));
      String inputLine;
      while ((inputLine = in.readLine()) != null) {
        res.append(inputLine);
      }
      in.close();
    } catch (Exception e) {
      System.err.println("Failed to read RPX UserID: " + e);
    }
    return res.toString();
  }

%>
<%
  String error_msg = "";
  String redirect = request.getParameter("goto");

  String action = request.getParameter("action");
  String token = request.getParameter("token");

  String userID = getUserID(session);

  //System.out.println("token: " + token);
  //System.out.println("userID: " + userID);

  if ("logout".equals(action)) {
    clearUserID(session);
    response.sendRedirect(redirect);
  } else if (!"".equals(token)) {

    // just logged in
    // POST token and apiKey to: https://rpxnow.com/api/v2/auth_info
    String jsonuid = get_json_userid(token, rpxnow_key);
    if (jsonuid.length() > 0) {
      setUserID(session, jsonuid);
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
    if (userID != null) {
%>
You're logged in as 
<script>
   userID = <%= userID %>
   document.write(userID.profile.displayName);
</script>
<br>
<%
    } else {
      out.println("Nothing to see here");
    }
    out.println("</body></html>");
  }
%>
