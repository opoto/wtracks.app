<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; CHARSET=iso-8859-1">
    <title>
      Local Track Files
    </title>
  </head>
  <body>
  <h1>GPX Track Files saved on this server</h1>
  <ul>
  <?php

  function show_file($directory, $file) {
    $directory = substr($directory, 2);
    $dir = base64_decode($directory);
    $f = base64_decode(substr($file, 0, -4));
    echo "<li>[$dir] <a href='/?gpx=tracks/$directory/$file'>$f</a></li>";
  }

  function move_file($directory, $file) {
    copy("$directory/$file", "$directory/aHR0cDovL3BvdG8ubXlvcGVuaWQuY29tLw==/"
         .base64_encode(substr($file, 0, -4)).".gpx");
  }



  function search($file_pattern, $directory, $recursive, $file_processor){
   if(is_dir($directory)){
     $direc = opendir($directory);
     while (false !== ($file = readdir($direc))){
       if ($file !="." && $file != ".."){
         if (is_file($directory."/".$file)){
           if (preg_match("/$file_pattern/i", $file)){
             $file_processor($directory, $file);
           }
         } else if($recursive && is_dir($directory."/".$file)) {
           if ($dir_processor) {
             $dir_processor($directory."/".$file);
           }
           search($file_pattern, $directory."/".$file, $recursive, $file_processor);
         }
       }
     }
     closedir($direc);
   }
   return ;
  }

  if ($_REQUEST['action'] == "move") {
    search("\.gpx$", ".", false, move_file);
  } else {
    search("\.gpx$", ".", true, show_file);
  }
  
  ?>
  </ul>
  </body>
</html>
