--
-- Written by xphh 2015 with 'MIT License'
--
local req = http.req

local f = nil
local page = req.uri_path

-- check whether uri start with '/'
local first = string.sub(page, 1, 1)
if first ~= "/" then
	http:exit(403)
	return
end

-- replace parent dir '..' for safety
page = string.gsub(page, "%.+", "%.")

local interpret = nil
if config.load_interpreter then
	interpret = require "lnet.model_http.interpreter"
end

local last = string.sub(page, #page - 1)
if last == "/" then
	for i,v in ipairs(config.default_page) do
		f = io.open(config.webpage_root..page..v, "rb")
		if f ~= nil then
			page = page..v
			break
		end
	end
else
	f = io.open(config.webpage_root..page, "rb")
end

if f == nil then
	http:exit(404)
	return
end

local source = f:read("*all")
f:close()

local ext = ""
local pos = string.find(page, "%.")
if pos ~= nil then
	ext = string.sub(page, pos + 1)
end

if ext == "lua" and interpret ~= nil then
	source, err = interpret(source)
	if source == nil then
		http:exit(503, "while interpret '"..page.."': "..err)
		return
	end
end

http.resp.headers["Content-Type"] = config.mime_types[ext] or "application/octet-stream"
http.resp.content = source
