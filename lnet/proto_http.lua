--
-- Written by xphh 2015 with 'MIT License'
--

local function getline(data, begin)
	local pos = string.find(data, "\r\n", begin)
	if pos ~= nil then
		return string.sub(data, begin, pos - 1), pos + 2
	end
end

local function split(str, div)
	local arr = {}
	local begin = 1
	local i = 1
	while true do
		local pos = string.find(str, div, begin)
		if pos == nil then
			arr[i] = string.sub(str, begin)
			break
		end
		arr[i] = string.sub(str, begin, pos - 1)
		begin = pos + 1
		i = i + 1
	end
	return arr
end

local function parse_headline(data, begin)
	local line, begin = getline(data, begin)
	if line == nil then
		return 0
	end
	local _, _, method, uri, protocol = string.find(line, "(.+)%s+(.+)%s+(.+)")
	if method == nil or uri == nil or protocol == nil then
		return -1, "headline["..line.."] parse fail"
	end
	if protocol ~= "HTTP/1.0" and protocol ~= "HTTP/1.1" then
		return -1, "http version "..protocol.." unsupported"
	end
	return begin, nil, line, method, uri, protocol
end

local function parse_uri(uri)
	local arr = split(uri, "?")
	local path = arr[1]
	local argsline = arr[2]
	if argsline == nil then
		return path, {}
	end
	local args = {}
	arr = split(argsline, "&")
	for i, v in ipairs(arr) do
		arr = split(v, "=")
		args[arr[1]] = arr[2]
	end
	return path, args
end

local function parse_statusline(data, begin)
	local line, begin = getline(data, begin)
	if line == nil then
		return 0
	end
	local _, _, protocol, code, desc = string.find(line, "(.+)%s+(%d+)%s+(.+)")
	if protocol == nil or code == nil or desc == nil then
		return -1, "status line["..line.."] parse fail"
	end
	if protocol ~= "HTTP/1.0" and protocol ~= "HTTP/1.1" then
		return -1, "http version unsupported"
	end
	return begin, nil, line, protocol, code, desc
end

local function parse_headers(data, begin)
	local headers = {}
	while true do
		local _, ep, header, info = string.find(data, "([^\n]+)%s*:%s*([^\n]*)\r\n", begin)
		if header == nil then
			break
		end
		begin = ep + 1
		headers[string.lower(header)] = info
	end
	return begin, nil, headers
end

local function parse_chunked_content(data, begin)
	local content = ""
	local line
	while true do
		if begin >= #data then
			return 0
		end
		line, begin = getline(data, begin)
		local length = tonumber(line, 16) -- length in HEX
		if length == nil or length < 0 then
			return -1, "parse chunk length error"
		elseif length == 0 then
			return begin, nil, content
		end
		local chunk = string.sub(data, begin, begin + length - 1)
		if chunk == nil then
			return 0
		end
		content = content..chunk
		begin = begin + length + 2
	end
end

-- return (parsed, err, req)
-- parsed =  0 for 'incomplete'
-- parsed = -1 for 'error'
-- parsed >  0 for 'the length of data parsed'
local function http_parse(data, full)
	local req = {}
	local begin = 1
	-- parse request headline
	begin, err, req.headline, req.method, req.uri, req.protocol = parse_headline(data, begin)
	if begin < 0 then
		return -1, err, req
	elseif begin == 0 then
		return 0
	end
	req.uri_path, req.uri_args = parse_uri(req.uri)
	-- if full, parse response status line
	if full ~= nil then
		begin, err, req.statusline, req.protocol, req.code, req.desc = parse_statusline(data, begin)
		if begin < 0 then
			return -1, err, req
		elseif begin == 0 then
			return 0
		end
	end
	-- parse headers
	begin, err, req.headers = parse_headers(data, begin)
	if begin < 0 then
		return -1, err, req
	elseif begin == 0 then
		return 0
	end
	-- parse content
	if req.headers["transfer-encoding"] == "chunked" then
		begin, err, req.content = parse_chunked_content(data, begin)
		if begin < 0 then
			return -1, err, req
		elseif begin == 0 then
			return 0
		else
			return begin - 1, nil, req
		end
	elseif req.headers["content-length"] == nil then
		return begin - 1, nil, req
	else
		local clen = tonumber(req.headers["content-length"])
		if clen == nil or clen < 0 then
			return -1, "parse content length fail", req
		elseif begin + clen - 1 > #data then
			return 0
		else
			req.content = string.sub(data, begin, begin + clen - 1)
			return begin + clen - 1, nil, req
		end
	end
	return 0
end

-- return http packet buffer
local function http_generate(http)
	local buf
	if http.code ~= nil then
		buf = http.protocol.." "..http.code.." "..http.desc.."\r\n"
	elseif http.method ~= nil then
		buf = http.method.." "..http.uri.." "..http.protocol.."\r\n"
	else
		return nil, "unrecognized http table"
	end
	if http.headers["Transfer-Encoding"] == nil then
		local clen = http.content and #http.content or 0
		http.headers["Content-Length"] = clen
	end
	for k in pairs(http.headers) do
		buf = buf..k..": "..http.headers[k].."\r\n"
	end
	buf = buf.."\r\n"
	if http.headers["Transfer-Encoding"] == "chunked" then
		if http.content ~= nil then
			buf = buf..string.format("%x", #http.content).."\r\n"
			buf = buf..http.content.."\r\n"
		end
		buf = buf.."0\r\n"
	else
		if http.content ~= nil then
			buf = buf..http.content
		end
	end
	return buf
end

-- DUMP
return {
	parse = http_parse,
	generate = http_generate,
}
