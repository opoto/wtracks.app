<?php
header('Content-type: text/xml');
@readfile($_SERVER["QUERY_STRING"])
?>
