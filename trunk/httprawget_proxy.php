<?php
header('Content-type: text/plain');
@readfile($_SERVER["QUERY_STRING"])
?>
