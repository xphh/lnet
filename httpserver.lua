local Server = require "lnet.server"

-- one http server
Server:new {
	model = "http.default", -- a http server, and configured by 'lnet/model_http/config/default.lua'
	ip = "0.0.0.0",
	port = 80,
	nfd = 100000, -- maximum connections per thread
	nthread = 1, -- best set to cpu numbers 
}

-- another http server
Server:new {
	model = "http.default",
	ip = "0.0.0.0",
	port = 8080,
	nfd = 10000,
	nthread = 2,
}

-- run all servers
Server.go()
