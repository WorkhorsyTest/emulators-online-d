<?php
header("Access-Control-Allow-Origin: *");
header("Content-type: application/json");
session_name('Global');
session_id('TEST');
session_start();

// Make the array to hold the peers, files, and values
if (!array_key_exists("files", $_SESSION)) { $_SESSION["files"] = []; }
if (!array_key_exists("peers", $_SESSION)) { $_SESSION["peers"] = []; }
if (!array_key_exists("values", $_SESSION)) { $_SESSION["values"] = []; }

$action = $_REQUEST["action"];

if ($action == "set_value") {
	// Get the arguments
	$id = $_REQUEST["id"];
	$key = $_REQUEST["key"];
	$value = $_REQUEST["value"];

	// Un url encode, un base64, and un gzip the value
	//$value = urldecode($value);
	//$value = base64_decode($value);
	//$value = gzuncompress($value);

	// Make sure the value for this user is initialized
	if (!array_key_exists($id, $_SESSION["values"])) {
		$_SESSION["values"][$id] = [];
	}

	// Save the value
	$_SESSION["values"][$id][$key] = $value;
	echo json_encode($value);
} else if ($action == "get_value") {
	// Get the arguments
	$id = $_REQUEST["id"];
	$key = $_REQUEST["key"];

	$value = null;
	if (array_key_exists($id, $_SESSION["values"])) {
		if (array_key_exists($key, $_SESSION["values"][$id])) {
			$value = $_SESSION["values"][$id][$key];
		}
	}
	echo json_encode($value);
} else if ($action == "set_peer") {
	$peerid = $_REQUEST["peerid"];
	$_SESSION["peers"][$peerid] = 1;
} else if ($action == "remove_peer") {
	$peerid = $_REQUEST["peerid"];
	unset($_SESSION["peers"][$peerid]);
} else if ($action == "get_peers") {
	$keys = array_keys($_SESSION["peers"]);
	echo json_encode($keys);
} else if ($action == "get_file") {
	// Get the peerid and file
	$peerid = $_REQUEST["peerid"];
	$file = $_REQUEST["file"];

	// Save it in the session
	$_SESSION["files"][$peerid] = $file;

	// Show all the peers and files
	echo json_encode($_SESSION["files"]);
} else if ($action == "clear") {
	// Reset the files
	$_SESSION["peers"] = [];
	$_SESSION["files"] = [];
	$_SESSION["values"] = [];
}

session_write_close();
?>

