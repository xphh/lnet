--
-- Written by xphh 2015 with 'MIT License'
--
local core = require "lnet.core"
local TcpSocket = core.tcp
local Poll = core.poll

local Server = {
	listener = -1,
	params = {},
	parr = {},
}

function Server:new(params)
	local o = Server
	o.listener, err = TcpSocket:open(params.ip, params.port)
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
	return o
end

function Server:listen()
	self.listener:listen()
	local p = self.params
	print("server["..p.model.."] start listen at "..p.ip..":"..p.port.." with "..p.nfd.."x"..p.nthread)
end

function Server:run()
	local id = 0
	while true do
		local bread = self.listener:wait(true, false, -1)
		if bread then
			local fd = self.listener:accept()
			if fd ~= -1 then
				id = id + 1
				if id > self.params.nthread then id = 1 end
				self.parr[id]:control(fd, true, false, false)
			end
		end
	end
end

return Server