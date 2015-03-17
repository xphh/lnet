--
-- Written by xphh 2015 with 'MIT License'
--

-- version info
lnet_version = "lnet-0.1.0"

-- global http config
config = {}

-- global http packet object
http = {
	req = {}, 
	resp = {},
}

-- our http user-agent
local user_agent = "Lua httpserver "..lnet_version
local default_resp = {code = 200, desc = "OK", headers = {["User-Agent"] = user_agent}}

local core = require "lnet.core"
local Sync = core.sync

local proto = require "lnet.proto_http"

local function datestr()
	return os.date(config.logs_date_format)
end

local function log_access(req, peer)
	req = req or http.req
	peer = peer or http.peer
	local ua = req.headers["user-agent"] or ""
	local msg = datestr().." - "..peer.ip..":"..peer.port.." - "..req.headline.." - User-Agent["..ua.."]"
	Sync.enter()
	config.access_log:write(msg.."\r\n")
	config.access_log:flush()
	Sync.leave()
end

local function log_info(info)
	local msg = datestr().." - "..info
	Sync.enter()
	config.error_log:write(msg.."\r\n")
	config.error_log:flush()
	Sync.leave()
end

local function log_error(err, req, peer)
	req = req or http.req
	req.headline = req.headline or ""
	peer = peer or http.peer
	local msg = datestr().." - "..peer.ip..":"..peer.port.." - "..req.headline.." - "..err
	Sync.enter()
	config.error_log:write(msg.."\r\n")
	config.error_log:flush()
	Sync.leave()
end

local urireg = {}
local mapping = {}

local function sethandler()
	mapping = config.uri_mapping
	local i = 1
	for k in pairs(mapping) do
		urireg[i] = k
		i = i + 1
	end
	local f = function(k1, k2) if #k1 > #k2 then return true else return false end end
	table.sort(urireg, f)
end

local function gethandler(uri)
	for _,k in ipairs(urireg) do
		if string.find(uri, k) ~= nil then
			if (mapping[k].chunk == nil) or (not config.code_cache) then
				mapping[k].chunk, mapping[k].err = loadfile(config.http_handler_dir.."/"..mapping[k].handler)
			end
			return mapping[k].chunk, mapping[k].err
		end
	end
end

local function resp_exit(code)
	local desc = "Error"
	if code == 200 then desc = "OK"
	elseif code == 400 then desc = "Bad Request"
	elseif code == 401 then desc = "Unauthorized"
	elseif code == 403 then desc = "Forbidden"
	elseif code == 404 then desc = "Not Found"
	elseif code == 500 then desc = "Internal Error"
	end
	http.resp.code = code
	http.resp.desc = desc
	if 400 <= code and code < 600 then
		http.resp.headers["Content-Type"] = "text/html"
		http.resp.content = '<h1 align="center">'..http.resp.code..' '..http.resp.desc..'</h1><hr/><p align="center">'..lnet_version..'</p>'
	end
end

-- start
require "lnet.model_http.config"
http.err = log_error
http.exit = resp_exit
sethandler()
log_info("worker init")
if not config.code_cache then
	log_info("warning: code cache is off")
end

local model = {

	timeout = function ()
		return config.keep_alive
	end,
	
	-- return (parsed, err, respbuf)
	input = function (data, peer)
		-- parse http request
		local parsed, err, req = proto.parse(data)
		if parsed < 0 then
			log_error(err, req, peer)
			return -1, err
		elseif parsed == 0 then
			return 0
		end
		-- handle http request
		log_access(req, peer)
		http.peer = peer
		http.req = req
		http.resp = default_resp
		local handler, err = gethandler(req.uri)
		if handler == nil then
			log_error(err)
			resp_exit(500)
		else
			env = {}
			setmetatable(env, {__index = _G})
			setfenv(1, env)
			local ret, err = pcall(handler)
			if not ret then
				log_error(err)
				resp_exit(500)
			end
		end
		-- generate http response
		http.resp.protocol = http.req.protocol
		if config.chunked_mode then
			http.resp.headers["Transfer-Encoding"] = "chunked"
		end
		local respbuf, err = proto.generate(http.resp)
		if respbuf == nil then
			log_error(err, req, peer)
		end
		return parsed, nil, respbuf
	end,
	
}

return model