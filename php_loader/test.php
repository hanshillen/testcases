<?php

$myFile = "index.html"; // normally you would get this through a file path provided as a GET variable in the URL

$pageContent = file_get_contents($myFile);

$headerContent = file_get_contents("header.include");
$footerContent = file_get_contents("footer.include");

if (!$pageContent || !$headerContent || !$footerContent) {
	die();
}

$pageContent = str_replace("<!--HEADER-->", $headerContent, $pageContent);
$pageContent = str_replace("<!--FOOTER-->", $footerContent, $pageContent);

print $pageContent;

?>