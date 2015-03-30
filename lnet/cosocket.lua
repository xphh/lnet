--
-- Written by xphh 2015 with 'MIT License'
--
local core = require "lnet.core"
local Socket = core.socket
local Poll = core.poll

local p = Poll:new(_G["_POLL"])

-- key:fd, vlaue:coroutine
local COMAP = {}

-- co fd list
local FDLIST = {}

-- timeout (sec) for all socket
local TIMEOUT = 3.0

-- object extends from Socket
local CoSocket = Socket:new(-1)

function CoSocket:setevent(bread, bwrite)
	local co = coroutine.running()
	COMAP[self.fd] = co
	table.insert(FDLIST, {fd = self.fd, t = os.clock(), co = co})
	p:control(self.fd, bread, bwrite, false)
end

function CoSocket:setread()
	self:setevent(true, false)
end

function CoSocket:setwrite()
	self:setevent(false, true)
end

function CoSocket.clear(fd)
	p:control(fd, false, false, true)
	COMAP[fd] = nil
	for i,v in ipairs(FDLIST) do
		if v.fd == fd then
			table.remove(FDLIST, i)
			break
		end
	end
end

-- override wait/connect/send/recv

function CoSocket:wait()
	local begin = os.clock()
	coroutine.yield()
	if os.clock() - begin >= TIMEOUT then
		return -1, "timeout"
	else
		return 0
	end
end

function CoSocket:connect(ip, port)
	local ret, err = Socket.connect(self, ip, port)
	if ret < 0 then
		return ret, err
	end
	self:setwrite()
	return self:wait()
end

function CoSocket:send(data, ip, port)
	local remain_data = data
	local remain_len = #data
	while true do
		local sndlen, err = Socket.send(self, remain_data, ip, port)
		if sndlen < 0 then
			return -1, err
		else
			remain_data = string.sub(remain_data, sndlen + 1)
			remain_len = remain_len - sndlen
			if remain_len <= 0 then
				return #data
			else
				self:setwrite()
				local ret, err = self:wait()
				if ret < 0 then
					return #data - remain_len, err
				end
			end
		end
	end
end

-- if cond == nil, recv until disconnected (if udp, recv one pack)
-- if cond is number, recv until cond bytes are received
-- if cond is string, recv until cond is received
function CoSocket:recv(cond)
	local total_data = ""
	local total_len = 0
	local peer_ip = ""
	local peer_port = 0
	while true do
		self:setread()
		local ret, err = self:wait()
		if ret < 0 then
			break
		end
		local rcvlen, data
		rcvlen, data, peer_ip, peer_port = Socket.recv(self, 8000)
		if rcvlen < 0 then
			break
		end
		total_len = total_len + rcvlen
		total_data = total_data..data
		if cond ~= nil then
			if type(cond) == "number" and total_len >= cond then
				break
			elseif string.find(total_data, cond) ~= nil then
				break
			end
		else
			if self.udp then
				break
			end
		end
	end
	return total_len, total_data, peer_ip, peer_port
end

-- set timeout
function CoSocket.settimeout(to)
	TIMEOUT = to
end

-- save errhandlers
local ERRHANDLERS = {}

-- resume cosocket's coroutine
function CoSocket.coresume(co)
	local res, err = coroutine.resume(co)
	if not res then
		ERRHANDLERS[co](err)
	end
	if coroutine.status(co) ~= "suspended" then
		ERRHANDLERS[co] = nil
	end
end

-- create a coroutine for cosocket!
function CoSocket.coroutine(func, errhandler)
	local co = coroutine.create(func)
	ERRHANDLERS[co] = errhandler
	CoSocket.coresume(co)
end

-- get coroutine by fd, and resume co
-- if co exists, return true, or false
function CoSocket.resume(fd)
	local co = COMAP[fd]
	if co ~= nil then
		CoSocket.clear(fd)
		CoSocket.coresume(co)
		return true
	else
		return false
	end
end

-- return next timeout (sec)
function CoSocket.getnext()
	local now = os.clock()
	while FDLIST[1] ~=nil do
		local to = FDLIST[1].t + TIMEOUT
		if now >= to then
			CoSocket.resume(FDLIST[1].fd)
		else
			return to - now
		end
	end
	return -1
end

---------------
return CoSocket
