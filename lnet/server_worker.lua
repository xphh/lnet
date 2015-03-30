--
-- Written by xphh 2015 with 'MIT License'
--
local core = require "lnet.core"
local Socket = core.socket
local Poll = core.poll

local tid = _G["_THREADID"]
local p = Poll:new(_G["_POLL"])
local ctxstring = _G["_CTXSTRING"]

-- parse modeltype & modelctx
_MODELTYPE = ctxstring
_MODELCTX = nil
local pos = string.find(ctxstring, "%.")
if pos ~= nil then
	_MODELTYPE = string.sub(ctxstring, 1, pos - 1)
	_MODELCTX = string.sub(ctxstring, pos + 1)
end
local model = require("lnet.model_".._MODELTYPE)

local CLIENTS = {}
local Client = {}

function Client:new(fd)
	local o = {
		tcp = Socket:new(fd),
		sndbuf = "",
		rcvbuf = "",
		timestamp = 0
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Client:recv()
	local rcvlen, data, peer_ip, peer_port = self.tcp:recv(8000)
	if rcvlen > 0 then
		self.rcvbuf = self.rcvbuf..data
		self.timestamp = os.clock()
		return true, {ip = peer_ip, port = peer_port}
	end
	return false
end

function Client:consume(length)
	if length < #self.rcvbuf then
		self.rcvbuf = string.sub(self.rcvbuf, length + 1)
	else
		self.rcvbuf = ""
	end
end

function Client:send(data)
	if data ~= nil then
		self.sndbuf = self.sndbuf..data
	end
	local sndlen = self.tcp:send(self.sndbuf)
	if sndlen == #self.sndbuf then
		self.sndbuf = ""
		p:control(self.tcp.fd, true, false, true)
	elseif 0 <= sndlen and sndlen < #self.sndbuf then
		self.sndbuf = string.sub(self.sndbuf, sndlen + 1)
		p:control(self.tcp.fd, true, true, true)
	elseif sndlen < 0 then
		return false
	end
	return true
end

function Client:close(data)
	p:control(self.tcp.fd, false, false, true)
	self.tcp:close()
end

local function getclient(fd)
	if CLIENTS[fd] == nil then
		CLIENTS[fd] = Client:new(fd)
	end
	return CLIENTS[fd]
end

local function rmvclient(fd)
	if CLIENTS[fd] ~= nil then
		CLIENTS[fd]:close()
		CLIENTS[fd] = nil
	end					
end

local last_check_time = os.clock()
local function checkclients()
	local now = os.clock()
	local timeout = model.timeout
	if (now - last_check_time >= 1) and (timeout > 0) then
		for k in pairs(CLIENTS) do
			if now - CLIENTS[k].timestamp >= timeout then
				rmvclient(CLIENTS[k])
			end
		end
		last_check_time = now
	end
end

local function handle_event(fd, bread, bwrite)
	if bread then
		local client = getclient(fd)
		local sendfunc = function (data) client:send(data) end
		local ret, peer = client:recv()
		if not ret then
			rmvclient(fd)
		elseif model.size_limit > 0 and #client.rcvbuf > model.size_limit then
			rmvclient(fd)
		else
			local parsed, err = model.input(client.rcvbuf, peer, sendfunc)
			if parsed > 0 then
				client:consume(parsed)
			elseif parsed < 0 then
				rmvclient(fd)
			end
		end 
	end
	if bwrite then
		local client = getclient(fd)
		local ret = client:send()
		if not ret then
			rmvclient(fd)
		end
	end
end

local CoSocket = require "lnet.cosocket"

--
-- main loop
--
while true do
	local to = CoSocket.getnext()
	local n = p:poll(to * 1000)
	if n > 0 then
		for i = 1, n do
			local fd, bread, bwrite = p:event(i)
			local iscosock = CoSocket.resume(fd)
			if not iscosock then
				handle_event(fd, bread, bwrite)
			end
		end
	end
	checkclients()
end
