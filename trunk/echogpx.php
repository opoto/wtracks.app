<?php
  header('Content-type: text/xml');
  echo str_replace('\"', '"', $_POST["gpxarea"]);
?>
