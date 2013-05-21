<?php

// database file name
$database = "example.db";

// database password
$password = "123456";

// returns new instance of PDO object
function getPDO($database) {
	try {
		$pdo = new PDO("sqlcipher:" . $database);
	} catch (PDOException $e) {
		die($e->getMessage() . PHP_EOL);
	}

	return $pdo;
}

//
// Create new example database with one table
// (it can be done through sqlcipher command line client)
//

$sql = "PRAGMA key = '$password';
PRAGMA encoding = \"UTF-8\";
PRAGMA auto_vacuum = 2;
PRAGMA incremental_vacuum(10);

CREATE TABLE `test` (
        `id`    INTEGER NOT NULL PRIMARY KEY,
        `value` TEXT NOT NULL
);";

$pdo = getPDO($database);

if ($pdo->exec($sql) === false) {
	$error = $pdo->errorInfo();
	die($error[0] . ": " . $error[2] . PHP_EOL);
}

//
// Use example database
//

// set encryption key before any sql command
$sql = "PRAGMA key = '$password'";
$pdo = getPDO($database);

if ($pdo->exec($sql) === false) {
	$error = $pdo->errorInfo();
	die($error[0] . ": " . $error[2] . PHP_EOL);
}

// insert rows
$sql = "INSERT INTO `test` VALUES (1, 'value1');
INSERT INTO `test` VALUES (2, 'value2');
INSERT INTO `test` VALUES (3, 'value3');";

if ($pdo->exec($sql) === false) {
	$error = $pdo->errorInfo();
	die($error[0] . ": " . $error[2] . PHP_EOL);
}

// select rows
$result = $pdo->query("SELECT * FROM `test`");

if ($result === false) {
	$error = $pdo->errorInfo();
	die($error[0] . ": " . $error[2] . PHP_EOL);
}

foreach ($result as $row) {
	print_r($row);
}
