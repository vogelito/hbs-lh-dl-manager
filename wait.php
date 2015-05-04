<?php
  $e = $_GET["e"];
  $url = "out/".$e.".zip";
  $debug = "out/".$e.".log";
?>

<html>
  <head>
    <title>LH Download Manager</title>
    <script src="//code.jquery.com/jquery-1.11.2.min.js"></script>
    <script src="//code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
    <script type="text/javascript">
var timerForLoadingResult=  setInterval(checkServerForFile,1000);

function checkServerForFile() {                
    $.ajax({
        type: "HEAD",
        cache: false,
        url: "<?php echo $url ?>", 
        statusCode: {
            200: function (response) {
                clearInterval(timerForLoadingResult);
                $('#show').html("Your files are ready! Please download them <a href=\"<?php echo $url ?>\">here</a>");
            }
        }
    });
}
    </script>
  </head>
  <body>
    Please be patient... Your files are being downloaded... You can see the log <a href="<?php echo $debug ?>">here</a><br>
    A link will appear here once your files are ready... <br>
    <div id="show" align="center"></div> 
  </body>
<head>
