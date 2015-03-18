--
-- Written by xphh 2015 with 'MIT License'
--

-- http server version info and user agent
config.version_info = "lnet-0.1.0"
config.user_agent = "Lua httpserver "..config.version_info

-- http session keep-alive time (sec)
config.keep_alive = 65

-- http transfer encoding use chunked mode
config.chunked_mode = false

-- maximum http packet size limit
config.http_size_limit = 1024*1024

-- code cache on/off
config.code_cache = true
if not config.code_cache then
	print("warning: code cache is off")
end

-- output error information to client (for debug mode)
config.output_error = true

-- logs parameters
-- make sure the directory exist or will not take effect
config.logs_dir = "lnet/model_http/logs"
config.logs_date_format = "%Y-%m-%d %H:%M:%S"
config.access_log = io.open(config.logs_dir.."/access.log", "a")
config.error_log = io.open(config.logs_dir.."/error.log", "a")
assert(config.access_log, "open access logfile fail")
assert(config.error_log, "open error logfile fail")

-- web pages root directory
config.webpage_root = "lnet/model_http/root"

-- default page names
config.default_page = {
	"index.htm",
	"index.html",
	"index.lua",
	-- add more here
}

-- Lua interpreter on/off (Lua code embedded in html)
config.load_interpreter = true

-- default http handler(lua file) dir
config.http_handler_dir = "lnet/model_http/handler"

-- URI mapping
-- key: the URI regexp
config.uri_mapping = {

	[".*"] = {
		handler = "default.lua"
	},
	
	["^/test"] = {
		handler = "test.lua"
	},
	
}

-- import mime types
require "lnet.model_http.mime"
