local Server = require "lnet.server"

-- server init parameters
local params = {
	model = "http.default", -- a http server, and configured by 'lnet/model_http/config/default.lua'
	ip = "0.0.0.0",
	port = 80,
	nfd = 100000, -- maximum connections per thread
	nthread = 1, -- best set to cpu numbers 
}

Server.go(params)
