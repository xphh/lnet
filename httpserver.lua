local Server = require "lnet.server"
local config = require "lnet.model_http.config"

-- You can modify parameters in 'lnet/model_http/config.lua'
Server.go(config.init)
