<?php
  $host = $_SERVER["HTTP_HOST"];
  include("config-$host.php"); // should define gmaps_key, ganalytics_key, rpxnow_key, and rpxnow_realm

  $error_msg = "";
  $redirect = urldecode($_REQUEST['goto']);

  function get_json_openid($token, $apiKey) {
    return file_get_contents("https://rpxnow.com/api/v2/auth_info?token=$token&apiKey=$apiKey");
  }

  $action = $_REQUEST["action"];
  $token = $_REQUEST["token"];
  $openID = $_COOKIE["LoginOpenID"];
  if ($action == "logout") {
    setcookie("LoginOpenID", "", time()-3600);
    header("Location: $redirect");
  } else if ($token != "") {
   
    // just logged in
    // POST token and apiKey to: https://rpxnow.com/api/v2/auth_info
    $response = get_json_openid($token, $rpxnow_key);
    if ($response && ($response != "")) {
      setcookie("LoginOpenID", urlencode($response), time()+7200);
      header("Location: $redirect");
    } else  {
      echo "Error: failed get auth info for token $token<br>";
      //echo $php_errormsg;
    }

  } else {
?>
<html>
<head>
<title>Login</title>
</head>
<body>
<?php
    if ($openID != "") {
      $openID = json_decode(urldecode($openID));
      echo "You're logged in as ".$openID->profile->displayName."<br>\n";
    } else {
      echo "Nothing to see here";
    }
    phpinfo();
    echo "</body></html>";
  }
?>
