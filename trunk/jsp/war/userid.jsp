<%@ page import="javax.servlet.http.HttpSession" %><%!
  String getUserID(HttpSession session) {
    return (String)session.getAttribute("LoginOpenID");
  }
  void setUserID(HttpSession session, String id) {
    session.setAttribute("LoginOpenID", id);
  }
  void clearUserID(HttpSession session) {
    session.removeAttribute("LoginOpenID");
  }
  boolean isUser(HttpSession session, String identifier) {
    String currentUser = getUserID(session);
    if (currentUser == null) {
      return false;
    }
    return currentUser.replaceAll("\\\\", "").indexOf(identifier) >= 0;
  }
%>