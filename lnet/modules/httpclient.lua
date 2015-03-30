--
-- Written by xphh 2015 with 'MIT License'
--
local core = require "lnet.core"
local Socket = require "lnet.cosocket"
local proto = require "lnet.proto_http"

local HttpClient = {}

local function parse_host(host)
	local protocol = "http"
	local fullname = host
	local sp, ep = string.find(host, "://")
	if sp ~= nil then
		protocol = string.sub(host, 1, sp - 1)
		fullname = string.sub(host, ep + 1)
	end
	if protocol ~= "http" then
		return nil, "unsupported protocol '"..protocol.."'"
	end
	local name = fullname
	local port = 80
	local sp, ep = string.find(fullname, ":")
	if sp ~= nil then
		name = string.sub(fullname, 1, sp - 1)
		port = tonumber(string.sub(fullname, ep + 1))
	end
	local ip = core.gethostbyname(name)
	if not ip then
		return nil, "cannot find host"
	end
	return {ip = ip, port = port}
end

function HttpClient.request(host, req)
	local addr, err = parse_host(host)
	if not addr then
		return nil, err
	end
	local tcp, err = Socket:tcp()
	if not tcp then
		return nil, err
	end
	local ret, err = tcp:connect(addr.ip, addr.port)
	if ret < 0 then
		tcp:close()
		return nil, err
	end
	local data, err = proto.generate(req)
	if not data then
		tcp:close()
		return nil, err
	end
	local sndlen, err = tcp:send(data)
	if sndlen < #data then
		tcp:close()
		return nil, err
	end
	local rcvlen, rcvbuf = tcp:recv()
	if rcvlen < 0 then
		tcp:close()
		return nil, err
	end
	tcp:close()
	local parsed, err, resp = proto.parse(rcvbuf, true)
	if parsed <= 0 then
		return nil, err
	end
	return resp
end

return HttpClient