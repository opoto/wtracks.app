<?php
  $oid = $_REQUEST['oid'];
  $userdir = "tracks/".base64_encode($oid);

  function show_file_href($directory, $file) {
    $trackname = base64_decode(substr($file, 0, -4));
    echo "<a href='javascript:wt_loadGPX($directory/$file);'>$trackname</a><br>";
  }
  function show_file_option($directory, $file) {
    $trackname = base64_decode(substr($file, 0, -4));
    echo "<option value='$directory/$file'>$trackname</option>\n";
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
           search($file_pattern, $directory."/".$file, $recursive, $file_processor);
         }
       }
     }
     closedir($direc);
   }
   return ;
  }

  $delete = $_REQUEST['delete'];
  if ($delete != "") {
    if (strpos($delete, $userdir) == 0)	{
      // ok, deleted track belongs to registered user
      unlink($delete);
    }
  }
  search("\.gpx$", $userdir, false, show_file_option);
?>

