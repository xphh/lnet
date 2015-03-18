local req = http.req

local uri_args = ""
for k in pairs(req.uri_args) do
	if string.len(uri_args) > 0 then uri_args = uri_args.."&" end
	uri_args = uri_args..k.."="..req.uri_args[k]
end

local headers = ""
for k in pairs(req.headers) do
	if string.len(headers) > 0 then headers = headers.."\r\n" end
	headers = headers..k..": "..req.headers[k]
end

local info = "Hello World\n\n"
info = info.."HTTP Request Protocol = "..req.protocol.."\n"
info = info.."HTTP Request Method = "..req.method.."\n"
info = info.."HTTP Request URI = "..req.uri.."\n"
info = info.."HTTP Request URI Path = "..req.uri_path.."\n"
info = info.."HTTP Request URI Args = "..uri_args.."\n"
info = info.."HTTP Request Headers:\n"..headers.."\n"
if http.req.content ~= nil then
	info = info.."HTTP Request Content:\n"..req.content.."\n"
end

http.resp.code = 200
http.resp.desc = "OK"
http.resp.headers["Content-Type"] = "text/plain"
http.resp.content = info
