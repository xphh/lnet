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

local function getline(data, begin)
	local pos = string.find(data, "\r\n", begin)
	if pos ~= nil then
		return string.sub(data, begin, pos - 1), pos + 2
	end
end

local function parse_chunked_content(data, begin)
	local content = ""
	local line
	while true do
		if begin >= #data then
			return 0
		end
		line, begin = getline(data, begin)
		local length = tonumber(line)
		if length == nil or length < 0 then
			return -1
		elseif length == 0 then
			return begin, content
		end
		local chunk = string.sub(data, begin, begin + length - 1)
		if chunk == nil then
			return 0
		end
		content = content..chunk
		begin = begin + length + 2
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
	
	parse = function (data, peer)
		local req = {}
		local begin = 1
		local line, begin = getline(data, begin)
		if line == nil then
			return 0
		end
		local _, _, method, uri, protocol = string.find(line, "(.+)%s+(.+)%s+(.+)")
		if method == nil or uri == nil or protocol == nil then
			log_error("headline["..line.."] parse fail")
			return -1
		end
		if protocol ~= "HTTP/1.0" and protocol ~= "HTTP/1.1" then
			log_error("http version unsupported")
			return -1
		end
		req.headline = line
		req.method = method
		req.uri = uri
		req.protocol = protocol
		req.headers = {}
		while true do
			line, begin = getline(data, begin)
			if line == nil then
				return 0
			end
			if #line > 0 then
				local _, _, header, info = string.find(line, "(.+)%s*:%s*(.*)")
				if header == nil then
					log_error("header["..line.."] parse fail")
					return -1
				end
				req.headers[string.lower(header)] = info
			else
				break
			end
		end
		if req.headers["transfer-encoding"] == "chunked" then
			begin, req.content = parse_chunked_content(data, begin)
			if begin < 0 then
				return -1
			elseif begin == 0 then
				return 0
			elseif begin > config.content_length_allowed then
				log_error("chunked data too large", req, peer)
				return -1
			else
				return begin - 1, req
			end
		elseif req.headers["content-length"] == nil then
			return begin - 1, req
		else
			local clen = tonumber(req.headers["content-length"])
			if clen == nil or clen < 0 then
				return -1
			elseif begin + clen - 1 > #data then
				return 0
			elseif clen > config.content_length_allowed then
				log_error("content-length["..clen.."] too large", req, peer)
				return -1
			else
				req.content = string.sub(data, begin, begin + clen - 1)
				return begin + clen - 1, req
			end
		end
		return 0
	end,
	
	handle = function (req, peer)
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
		local resp = http.resp
		if config.chunked_mode then
			resp.headers["Transfer-Encoding"] = "chunked"
		else
			local clen = resp.content and #resp.content or 0
			resp.headers["Content-Length"] = clen
		end
		local respbuf = req.protocol.." "..resp.code.." "..resp.desc.."\r\n"
		for k in pairs(resp.headers) do
			respbuf = respbuf..k..": "..resp.headers[k].."\r\n"
		end
		respbuf = respbuf.."\r\n"
		if config.chunked_mode then
			if resp.content ~= nil then
				respbuf = respbuf..#resp.content.."\r\n"
				respbuf = respbuf..resp.content.."\r\n"
			end
			respbuf = respbuf.."0\r\n"
		else
			if resp.content ~= nil then
				respbuf = respbuf..resp.content
			end
		end
		return respbuf
	end,
}

return model