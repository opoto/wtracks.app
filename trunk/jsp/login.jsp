<%@ page import="java.util.*, java.io.*, java.net.*" %>
<%
  String host = request.getServerName();
%>
<%@ include file="config.jsp" %>
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

  String getCookieValue(Cookie[] cookies, String cookieName) {
    if (cookies != null) {
      for (int i = 0; i < cookies.length; i++) {
	if (cookies [i].getName().equals (cookieName)) {
	  return cookies[i].getValue();
	}
      }
    }
    return null;
  }

  Cookie setCookie(String name, String value, int age, String path) {
    Cookie myCookie = new Cookie("LoginOpenID", value);
    myCookie.setMaxAge(age);
    myCookie.setPath(path);
    return myCookie;
  }
%>
<%
  String error_msg = "";
  String redirect = request.getParameter("goto");

  String action = request.getParameter("action");
  String token = request.getParameter("token");
  String openID = getCookieValue(request.getCookies(), "LoginOpenID");

System.out.println("token: " + token);
System.out.println("openID: " + openID);

  if ("logout".equals(action)) {
    response.addCookie(setCookie("LoginOpenID", null, 0, "/"));
    response.sendRedirect(redirect);
  } else if (!"".equals(token)) {
   
    // just logged in
    // POST token and apiKey to: https://rpxnow.com/api/v2/auth_info
    String jsonoid = get_json_openid(token, rpxnow_key);
System.out.println("jsonoid: " + jsonoid);
    if (jsonoid.length() > 0) {
      response.addCookie(setCookie("LoginOpenID", URLEncoder.encode(jsonoid), (int)(new Date().getTime())+7200, "/"));
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
      openID = URLDecoder.decode(openID);
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
