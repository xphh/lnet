<html>
<head>
	<title>Lua HttpServer Default Page</title>
</head>
<body>
<h1>Welcome to Lua HttpServer</h1>
<hr>
<? return lnet_version ?>
<a href="https://github.com/xphh/lnet">[github]</a>
<? return os.date(config.logs_date_format) ?>
</body>
</html>