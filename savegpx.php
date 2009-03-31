<?php
  header('Content-type: application/octet-stream');
  header('Content-disposition: attachment; filename=your-track.gpx');
  echo str_replace('\"', '"', $_POST["gpxarea"]);
?>
