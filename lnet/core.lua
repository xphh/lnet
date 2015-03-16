--
-- Written by xphh 2015 with 'MIT License'
--
local lnet_openfunc, err = package.loadlib("lnet/core.dll", "luaopen_lnet")
if not lnet_openfunc then
	print(err)
end
local core = lnet_openfunc()

local TcpSocket = {
	fd = -1,
}

function TcpSocket:new(fd)
	local o = {fd = fd}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TcpSocket:open(ip, port)
	local fd, err
	if ip == nil then
		fd, err = core.tcp()
	else
		fd, err = core.tcp(ip, port)
	end
	if fd == -1 then
		return nil, err
	end
	return TcpSocket:new(fd)
end

function TcpSocket:close()
	return core.close(self.fd)
end

function TcpSocket:listen()
	return core.listen(self.fd)
end

function TcpSocket:accept()
	return core.accept(self.fd)
end

function TcpSocket:connect(ip, port)
	return core.connect(self.fd, ip, port)
end

function TcpSocket:send(data, ip, port)
	if ip == nil then
		return core.send(self.fd, data)
	else
		return core.send(self.fd, data, ip, port)
	end
end

function TcpSocket:recv(size)
	return core.recv(self.fd, size)
end

function TcpSocket:wait(bread, bwrite, timeout)
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
	return Poll:new(poll)
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
	tcp = TcpSocket,
	poll = Poll,
	sync = {
		enter = core.enter_sync,
		leave = core.leave_sync,
	},
}
