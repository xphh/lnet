<html>
<head>
<title>Lua HttpServer Default Page</title>
</head>
<body>
<h1>Welcome to Lua HttpServer</h1>
You request: <?echo(http.req.uri)?>
<hr>
<? echo(config.version_info) ?>
<a href="https://github.com/xphh/lnet">[github]</a>
<? echo(os.date(config.logs_date_format)) ?>
</body>
</html>