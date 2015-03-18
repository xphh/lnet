--
-- Written by xphh 2015 with 'MIT License'
--
local req = http.req

local f = nil
local page = req.uri_path

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
	http.exit(404)
	return
end

local ext = ""
local pos = string.find(page, "%.")
if pos ~= nil then
	ext = string.sub(page, pos + 1)
end

http.resp.code = 200
http.resp.desc = "OK"
http.resp.headers["Content-Type"] = config.mime_types[ext] or "application/octet-stream"
http.resp.content = f:read("*all")

f:close()
