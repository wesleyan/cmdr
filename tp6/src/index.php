<!DOCTYPE html>
<?php
include 'login.php';
session_start();
if($_SERVER['REMOTE_ADDR'] == $_SERVER['SERVER_ADDR']) {
  validateUser();
}
if(!isLoggedIn())
{
  header('Location: login.html');
  die;
}
?>
<html>
  <head>
    <title>TP6</title>
    slinky_styles
    <script src='script/vendor/json2.js'></script>
    <script src='script/vendor/jquery-1.7.1.js'></script>
    <script src='script/vendor/jquery.tmpl.js'></script>
    <script src='script/vendor/jquery.noisy.js'></script>
    <script src='script/vendor/underscore.js'></script>
    <script src='script/vendor/backbone.js'></script>
    slinky_scripts
  </head>
  <body>
    <div id='page'>
      <div id='top-bar'>
        <div class='label' id='room-label'></div>
        <div class='label' id='time-label'></div>
        <form name="logout" action="logout.php" method="post">
          <input type="submit" value="Logout" />
        </form>
      </div>
      <div id='main-view'>
        <div id='projector-pane'></div>
        <div id='action-pane'>
          <div class='action-module'>
            <ul class='action-list'></ul>
          </div>
        </div>
        <div id='context-pane'>
          <div class='context-area'></div>
          <div class='projector-overlay'></div>
        </div>
      </div>
    </div>
    <div id='lost-connection'>
      <div class='title'>Server Connection Lost</div>
      <div class='text'>The connection to the server has been lost. Try operating the equipment manually, or call 4959 for help.</div>
      <div class='reconnection-attempt'>
        <span>Will attempt to reconnect in</span>
        <span class='reconnection-counter'>2 seconds</span>
      </div>
      <div class='reconnecting' style='display:none;'>Reconnecting...</div>
    </div>
  </body>
</html>
