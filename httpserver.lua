local Server = require "lnet.server"

-- You can modify parameters as you wish
local server = Server:new {
	model = "http",
	ip = "0.0.0.0",
	port = 1234,
	nfd = 100000, -- maximum connections per thread
	nthread = 4, 
}

server:listen()

server:run()
