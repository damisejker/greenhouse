<?php
session_start(); // Start the session
header('Content-Type: application/json');

// Replace with your connection details
$servername = "localhost";
$username = "magismo_newera";
$password = "z65qdc3xmfq8";
$dbname = "magismo_school";

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
$conn->set_charset("utf8");

// Check connection
if ($conn->connect_error) {
    // If there is a connection error, send a JSON response with the error
    echo json_encode(['error' => "Connection failed: " . $conn->connect_error]);
}

/////////////////////////////////

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // It's good practice to check if the expected POST variables are set
    if (isset($_POST['username'], $_POST['left'], $_POST['top'])) {
        $username = $_POST['username'];
        $left = $_POST['left'];
        $top = $_POST['top'];
        $pot_id = isset($_POST['pot_id']) ? intval($_POST['pot_id']) : 1;

        // Валидация pot_id (должен быть от 1 до 10)
        if ($pot_id < 1 || $pot_id > 10) {
            echo json_encode(['error' => 'Invalid pot_id']);
            exit;
        }

        // Обновляем позицию в таблице user_pots
        $sql = "INSERT INTO user_pots (login, pot_id, pot_left, pot_top)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                pot_left = VALUES(pot_left),
                pot_top = VALUES(pot_top)";

        $stmt = $conn->prepare($sql);

        // Check if the statement was prepared successfully
        if ($stmt === false) {
            echo json_encode(['error' => "Error preparing the statement: " . $conn->error]);
            exit;
        }

        $stmt->bind_param("siss", $username, $pot_id, $left, $top);

        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => "Position saved successfully for pot $pot_id"]);
        } else {
            echo json_encode(['error' => "Error executing the statement: " . $stmt->error]);
        }

        $stmt->close();
    } else {
        echo json_encode(['error' => 'Required parameters are missing']);
    }
} else {
    // If not a POST request
    echo json_encode(['error' => 'Invalid request method']);
}
?>

