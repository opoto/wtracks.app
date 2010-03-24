<?php
header('Content-type: text/plain');
@readfile(urldecode($_SERVER["QUERY_STRING"]))
?>
