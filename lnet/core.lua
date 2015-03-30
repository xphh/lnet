--
-- Written by xphh 2015 with 'MIT License'
--
local lnet_openfunc, err = package.loadlib("lnet/core.dll", "luaopen_lnet")
if not lnet_openfunc then
	print(err)
end
local core = lnet_openfunc()

local Socket = {
	fd = -1,
	udp = false,
}

function Socket:new(fd, udp)
	local o = {fd = fd, udp = udp}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Socket:tcp(ip, port)
	local fd, err
	if ip == nil then
		fd, err = core.tcp()
	else
		fd, err = core.tcp(ip, port)
	end
	if fd == -1 then
		return nil, err
	end
	return self:new(fd, false)
end

function Socket:udp(ip, port)
	local fd, err
	if ip == nil then
		fd, err = core.udp()
	else
		fd, err = core.udp(ip, port)
	end
	if fd == -1 then
		return nil, err
	end
	return self:new(fd, true)
end

function Socket:close()
	return core.close(self.fd)
end

function Socket:listen()
	return core.listen(self.fd)
end

function Socket:accept()
	return core.accept(self.fd)
end

function Socket:connect(ip, port)
	return core.connect(self.fd, ip, port)
end

function Socket:send(data, ip, port)
	if ip == nil then
		return core.send(self.fd, data)
	else
		return core.send(self.fd, data, ip, port)
	end
end

function Socket:recv(size)
	return core.recv(self.fd, size)
end

function Socket:wait(bread, bwrite, timeout)
	return core.wait(self.fd, bread, bwrite, timeout)
end

local Poll = {
	p = nil,
}

function Poll:new(poll)
	local o = {p = poll}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Poll:create(nfd)
	local poll = core.create_poll(nfd)
	return self:new(poll)
end

function Poll:destroy(id)
	return core.destroy_poll(self.p)
end

function Poll:control(fd, bread, bwrite, inthread)
	return core.control_poll(self.p, fd, bread, bwrite, inthread)
end

function Poll:poll(timeout)
	return core.do_poll(self.p, timeout)
end

function Poll:event(id)
	return core.get_event(self.p, id)
end

function Poll:thread(filename, id, ctxstring)
	return core.poll_thread(self.p, filename, id, ctxstring)
end

return {
	socket = Socket,
	poll = Poll,
	sync = {
		enter = core.enter_sync,
		leave = core.leave_sync,
	},
	gethostbyname = core.gethostbyname,
}
