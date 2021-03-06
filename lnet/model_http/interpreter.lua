--
-- Written by xphh 2015 with 'MIT License'
--

local function dochunk(chunk)
	local output = ""
	-- set global echo function
	_G.echo = function (msg) output = output..msg end 
	chunk()
	return output
end

-- It works, but too simple to use.
return function (source)
	local out = ""
	local begin = 1
	while true do
		local p1 = string.find(source, "<%?", begin)
		if p1 == nil then
			out = out..string.sub(source, begin)
			return out
		end
		local p2 = string.find(source, "%?>", p1)
		if p2 == nil then
			return nil, "missing '?>'"
		end
		local html = string.sub(source, begin, p1 - 1) or ""
		local lua = string.sub(source, p1 + 2, p2 - 1) or ""
		local chunk, err = loadstring(lua)
		if chunk == nil then
			return nil, err
		end
		out = out..html..dochunk(chunk)
		begin = p2 + 2
	end
	return out
end
