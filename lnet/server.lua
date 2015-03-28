--
-- Written by xphh 2015 with 'MIT License'
--
local core = require "lnet.core"
local Socket = core.socket
local Poll = core.poll

local Server = {}

local SERVERS = {}

function Server:new(params)
	local o = {
		listener = -1,
		params = {},
		parr = {},
		id = 0,
	}
	o.listener, err = Socket:tcp(params.ip, params.port)
	if not o.listener then
		print("server create listener fail: "..err)
		return nil
	end
	o.params = params
	for i = 1, params.nthread do
		local p = Poll:create(params.nfd)
		o.parr[i] = p
		p:thread("lnet/server_worker.lua", i, params.model)
	end
	setmetatable(o, self)
	self.__index = self
	SERVERS[o.listener.fd] = o
	return o
end

function Server:listen()
	self.listener:listen()
	local p = self.params
	print("server["..p.model.."] start listen at "..p.ip..":"..p.port.." with "..p.nfd.."x"..p.nthread)
end

function Server:accept()
	local fd = self.listener:accept()
	if fd ~= -1 then
		self.id = self.id + 1
		if self.id > self.params.nthread then self.id = 1 end
		self.parr[self.id]:control(fd, true, false, false)
	end
end

function Server:run()
	self:listen()
	while true do
		local bread = self.listener:wait(true, false, -1)
		if bread then
			self:accept()
		end
	end
end

function Server.go()
	local p = Poll:create(64)
	for k in pairs(SERVERS) do
		local server = SERVERS[k]
		server:listen()
		p:control(server.listener.fd, true, false, false)
	end
	while true do
		local n = p:poll(-1)
		for i = 1,n do
			local fd, bread = p:event(i)
			local server = SERVERS[fd]
			if server ~= nil and bread then
				server:accept()
			end
		end
	end
end

return Server