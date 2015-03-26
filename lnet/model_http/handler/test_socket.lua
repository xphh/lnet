local Sock = require "lnet.cosocket"
local req = http.req

http.resp.headers["Content-Type"] = "text/plain"

local tcp = Sock:tcp()

-- connect self
local ret, err = tcp:connect("127.0.0.1", 1234)
if ret < 0 then
	http.resp.content = "connect fail: "..err
	tcp:close()
	return
end

-- get '/' page
local sndlen, err = tcp:send("GET / HTTP/1.0\r\n\r\n")
if sndlen < 0 then
	http.resp.content = "send fail: "..err
	tcp:close()
	return
end

-- recv response until '\r\n\r\n'
local rcvlen, data = tcp:recv("\r\n\r\n")
if rcvlen < 0 then
	http.resp.content = "recv fail: "..data
	tcp:close()
	return
end

-- show data
http.resp.content = data

tcp:close()
