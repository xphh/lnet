--
-- Written by xphh 2015 with 'MIT License'
--

-- global http config
require "lnet.model_http.config"

local core = require "lnet.core"
local Sync = core.sync

local proto = require "lnet.proto_http"

local function datestr()
	return os.date(config.logs_date_format)
end

local function log_access(req, peer)
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
	local headline = req.headline or ""
	local msg = datestr().." - "..peer.ip..":"..peer.port.." - "..headline.." - "..err
	Sync.enter()
	config.error_log:write(msg.."\r\n")
	config.error_log:flush()
	Sync.leave()
end

-- set handler array
-- we map the longest regexp
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

-- sandbox in a new enviroment
-- set http to globals
local function sandbox(handler)
	_G.http = http
	local res, err = pcall(handler)
	return res, err, http
end

-- create a sandbox
-- return http with http.resp filled
local function dohandler(handler, http)
	local env = {http = http}
	setmetatable(env, {__index = _G})
	setfenv(sandbox, env)
	return sandbox(handler)
end

-- set default http error output
local function set_http_error(http, code, err)
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
	if config.output_error and (err ~= nil) then
		http.resp.headers["Content-Type"] = "text/plain"
		http.resp.content = "server internal error: "..err
	else
		if 400 <= code and code < 600 then
			http.resp.headers["Content-Type"] = "text/html"
			http.resp.content = '<h1 align="center">'..http.resp.code..' '..http.resp.desc..'</h1><hr/><p align="center">'..config.version_info..'</p>'
		end
	end
end

--
-- chunk start here
--
sethandler()
log_info("worker init")
if not config.code_cache then
	log_info("warning: code cache is off")
end

local model = {
	-- session timeout time (sec)
	timeout = config.keep_alive or 0,
	-- max http size limit
	size_limit = config.http_size_limit	or 0,
}

-- return (parsed, err, respbuf)
function model.input(data, peer)
	-- parse http request
	local parsed, err, req = proto.parse(data)
	if parsed < 0 then
		log_error(err, req, peer)
		return -1, err
	elseif parsed == 0 then
		return 0
	end
	log_access(req, peer)
	-- http object
	local http = {
		peer = peer,
		req = req,
		resp = {code = 200, desc = "OK", headers = {["User-Agent"] = config.user_agent}},
		exit = set_http_error,
	}
	-- handle http
	local handler, err = gethandler(req.uri)
	if handler == nil then
		log_error(err, req, peer)
		set_http_error(http, 500, err)
	else
		local res, err, http = dohandler(handler, http)
		if not res then
			log_error(err, req, peer)
			set_http_error(http, 500, err)
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
end

return model
