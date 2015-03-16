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
3. Modify 'lnet/model_http/config.lua' as you like. How to configue? See annotations in config.lua, and to learn it yourself.
4. Modify 'httpserver.lua', set server parameters.
5. Run 'httpserver.lua'.

'lnet' is designed for good at restful HTTP services developping. As 'lnet' and its restful HTTP services framework is not perfect so far, it is still under construction, so you have to read source code for more infomations.

Thank you!
