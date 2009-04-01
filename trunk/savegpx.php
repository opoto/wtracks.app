<?php

$action = $_REQUEST['action'];
$gpxdata = str_replace('\"', '"', $_POST["gpxarea"]);
$oid = $_REQUEST['oid'];
$trackname = $_REQUEST['savedname'];
$host = $_SERVER['HTTP_HOST'];

if ($action == "Save") {
  header('Content-type: application/octet-stream');
  header('Content-disposition: attachment; filename=your-track.gpx');
  echo $gpxdata;
} else {
  $userdir = "tracks/".base64_encode($oid);
  if (!file_exists($userdir)) {
    mkdir($userdir);
  }
  $fname = base64_encode($trackname);
  $fpath = $userdir."/".$fname.".gpx";
  if (!file_put_contents($fpath, $gpxdata)) {
    echo "error: failed to save file...";
  } else {
    echo "<html><body>\n File saved: <a href='http://$host/$fpath'>$trackname</a>\n";
?>
    <script type='text/javascript'>self.close()</script>
    </body></html>
<?php
  }
}  
?>
