<?php

  $e = $_POST["email"];
  $lhp = $_POST["lhp"];
  $u = preg_replace("/@.*/", "", $e);

  if(!isset($_POST["email"])) {
    echo "<html>
  <head>
    <title>LH Course Content DL Manager</title>
  </head>
  <body>
    An unknown error occurred...
  </body>
</html>";
  } else {
    shell_exec('nohup fork.rb '.$e.' '.$lhp.' '.$u.' & >/dev/null 2>&1 &');
    header('Location: wait.php?e='.$u);
  }
?>
