<?php
if($_SERVER['REQUEST_METHOD'] == 'POST') {
session_start();
$username = $_POST['user'];
$password = $_POST['password'];

$db = new SQLite3('users.db');
$username = $db->escapeString($username);
$query = "SELECT password, salt
          FROM users
          WHERE username = '$username';";
$result = $db->query($query);
if($result == FALSE)
{
  error();
}
$userData = $result->fetchArray(SQLITE3_ASSOC);
$hash = hash('sha256', $userData['salt'] . hash('sha256', $password));
if($hash != $userData['password'])
{
  error();
}
else
{
  validateUser();
  header('Location: index.php');
}
}

function validateUser()
{
  session_regenerate_id ();
  $_SESSION['valid'] = 1;
}

function isLoggedIn()
{
  if(isset($_SESSION['valid']) && $_SESSION['valid']) {
    return true;
  }
  return false;
}

function logout()
{
  $_SESSION = array();
  session_destroy();
}

function error()
{
  print("<p>LOGIN FAILED: Incorrect Username/Password</p>");
  die;
}

?>
