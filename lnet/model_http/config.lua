-- http session keep-alive time (sec)
config.keep_alive = 65

-- http transfer encoding use chunked mode
config.chunked_mode = false

-- maximum http content length allowed
config.content_length_allowed = 1024*1024

-- code cache on/off
config.code_cache = true
if not config.code_cache then
	print("warning: code cache is off")
end

-- logs parameters
-- make sure the directory exist or will not take effect
config.logs_dir = "lnet/model_http/logs"
config.logs_date_format = "%Y-%m-%d %H:%M:%S"
config.access_log = io.open(config.logs_dir.."/access.log", "a")
config.error_log = io.open(config.logs_dir.."/error.log", "a")

-- default http handler(lua file) dir
config.http_handler_dir = "lnet/model_http"

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