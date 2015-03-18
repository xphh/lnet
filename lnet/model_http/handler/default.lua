--
-- Written by xphh 2015 with 'MIT License'
--
local req = http.req

local page = config.webpage_root..req.uri_path
local f = io.open(page, "rb")
if f == nil then
	http.exit(404)
	return
end

local ext = ""
local pos = string.find(req.uri_path, "%.")
if pos ~= nil then
	ext = string.sub(req.uri_path, pos + 1)
end

http.resp.headers["Content-Type"] = config.mime_types[ext] or "application/octet-stream"
http.resp.content = f:read("*all")

f:close()
