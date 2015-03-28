# lnet update 2015-03-28
Now multi-httpserver supported! See 'httpserver.lua'.

# lnet update 2015-03-25
Now cosocket supported!

What is cosocket? 'cosocket' is a socket API wapper for http handlers in lnet httpserver. It provides tcp/udp block operations but actually non-block in lnet httpserver thread. Yes, the name 'cosocket' means 'coroutine socket'. We yield out of the running corouine while doing some block operation (like connect and etc.), and resume back when the socket is ready.

To use cosocket, you have to require 'lnet.cosocket' explicitly in your lua code, and it returns an object:

local Socket = require "lnet.cosocket"
- tcp = Socket:tcp(ip, port) -- create a tcp socket object
- udp = Socket:udp(ip, port) -- create a udp socket object
- ret, err = Socket:connect(ip, port)
- sndlen, err = Socket:send(data, ip, port)
- rcvlen, data, ip, port = Socket:recv(condition)
- Socket.settimeout(sec)

To learn more, see 'lnet/cosocket.lua' and 'lnet/model_http/handler/test_socket.lua'.

# lnet update 2015-03-18
Now webpage supported!

1. static web pages: custom root directory, default pages, mime types, and etc.
2. dynamic web pages: Lua code embedded in html (very similar to PHP), see 'lnet/model_http/root/index.lua' for example.

So far, the Lua APIs for webpage and handler:

- echo (output messages into html, like php)
- http.peer.ip
- http.peer.port
- http.req.headline
- http.req.protocol
- http.req.method
- http.req.uri
- http.req.uri_path
- http.req.uri_args[key] = value
- http.req.headers[header] = info
- http.req.content
- http.resp.statusline
- http.resp.protocol
- http.resp.code
- http.resp.desc
- http.resp.headers[header] = info
- http.resp.content
- http:exit(code, err)

# lnet
This new toy is for those people who believe in that Lua can do everything, including httpserver.

The name 'lnet' is short for 'Lua Net', and what I have done here are as below:

1. Lua socket API (C extension library)
2. Lua IO poll API with multi-thread support (C extension library)
3. An event-model TCP server framework (Lua code)
4. An httpserver with restful HTTP services framework (Lua code)

You can use 'lnet' to do:

1. Normal socket develop
2. Custom TCP server develop
3. Server(backend) REST API develop

How to make, configure, and use 'lnet' httpserver:

1. Make sure you have already installed 'lua' or 'luajit'.
2. Make C library 'lnet/core.dll' (if Linux, run 'make').
3. Modify 'lnet/model_http/config/default.lua' as you like. How to configue? See annotations in config file, and to learn it yourself.
4. Modify 'httpserver.lua', set server parameters.
5. Run 'httpserver.lua'.

'lnet' is designed for good at restful HTTP services developping. As 'lnet' and its restful HTTP services framework is not perfect so far, it is still under construction, so you have to read source code for more infomations.

Thank you!
