--
-- Written by xphh 2015 with 'MIT License'
--

-- global http config
require "lnet.model_http.config"

local core = require "lnet.core"
local Sync = core.sync

local proto = require "lnet.proto_http"

local datestr_cache = os.date(config.logs_date_format)
local datestr_time = os.clock()
local function datestr()
	local now = os.clock()
	if now - datestr_time > 0.1 then
		datestr_cache = os.date(config.logs_date_format)
		datestr_time = now
	end
	return datestr_cache
end

local flush_time = os.clock()
local function log_access(req, peer)
	local ua = req.headers["user-agent"] or ""
	local msg = datestr().." - "..peer.ip.." - "..req.headline.." - User-Agent["..ua.."]\r\n"
	local now = os.clock()
	Sync.enter()
	config.access_log:write(msg)
	if now - flush_time > 1 then
		config.access_log:flush()
		flush_time = now
	end
	Sync.leave()
end

local function log_info(info)
	local msg = datestr().." - "..info.."\r\n"
	Sync.enter()
	config.error_log:write(msg)
	config.error_log:flush()
	Sync.leave()
end

local function log_error(err, req, peer)
	local headline = req.headline or ""
	local msg = datestr().." - "..peer.ip.." - "..headline.." - "..err.."\r\n"
	Sync.enter()
	config.error_log:write(msg)
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

local function http_response(http, sendfunc)
        local respbuf, err = proto.generate(http.resp)
        if respbuf == nil then
                log_error(err, req, peer)
        else
                sendfunc(respbuf)
        end
end

-- create a sandbox to do handler
local function sandbox(handler, http, sendfunc)
	local env = {http = http}
	setmetatable(env, {__index = _G})
	setfenv(1, env)
	-- set http to globals for handler
	_G.http = http
	handler()
	http_response(http, sendfunc)
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

-- return (parsed, err)
function model.input(data, peer, sendfunc)
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
		resp = {code = "200", desc = "OK", headers = {["User-Agent"] = config.user_agent}},
		exit = set_http_error,
	}
	-- set default response config
	http.resp.protocol = http.req.protocol
	if config.chunked_mode then
		http.resp.headers["Transfer-Encoding"] = "chunked"
	end
	if http.req.protocol == "HTTP/1.0" then
		if http.req.headers["connection"] == "keep-alive" and config.keep_alive > 0 then
			http.resp.headers["Connection"] = "keep-alive"
		else
			http.resp.headers["Connection"] = "close"
			parsed = -1 -- let server close the connection
		end
	else
		if http.req.headers["connection"] == "close" or config.keep_alive <= 0 then
			http.resp.headers["Connection"] = "close"
			parsed = -1 -- let server close the connection
		else
			http.resp.headers["Connection"] = "keep-alive"
		end
	end
	-- handle http
	local handler, err = gethandler(req.uri)
	if handler == nil then
		log_error(err, req, peer)
		set_http_error(http, 500, err)
		http_response(http, sendfunc)
	else
		-- create coroutine first
		local safectx = function () coroutine.wrap(sandbox)(handler, http, sendfunc) end
		-- then use pcall
		local res, err = pcall(safectx)
		if not res then
			log_error(err, req, peer)
			set_http_error(http, 500, err)
			http_response(http, sendfunc)
		end
	end
	return parsed
end

return model
