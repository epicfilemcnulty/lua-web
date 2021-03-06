local std = require("deviant")

local _M = { version = "0.3.1" }

local url = {}

url.parse = function(str)
	local url = {}
	url.scheme, url.host, url.port, url.path, url.query = string.match(
		str,
		"(https?)://([^:/]+):?([^/]*)(/?[^?]*)%??(.*)"
	)
	if not url.scheme then
		url.scheme, url.socket, url.path, url.query = string.match(str, "(unix):(/[^%:]+):(/?[^?]*)%??(.*)")
		url.path = "http:" .. url.path
	end
	if url.path == "" then
		url.path = "/"
	end
	url.port = tonumber(url.port)
	if url.query == "" then
		url.query = nil
	end
	return url
end

url.escape = function(str)
	if str then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w %-%_%.%~%%])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
		str = string.gsub(str, " ", "+")
	end
	return str
end

url.build = function(url)
	local url_string = ""
	if url.scheme then
		if url.scheme == "unix" and url.socket then
			url_string = url.scheme .. ":" .. url.socket
			-- don't forget to remove that 'http:' part from the path
			if url.path then
				url_string = url_string .. ":" .. string.sub(url.path, 6)
			end
			if url.query then
				url_string = url_string .. "?" .. url.query
			end
		else
			if url.host then
				url_string = url.scheme .. "://" .. url.host
			end
			if url.port then
				url_string = url_string .. ":" .. url.port
			end
			if url.path then
				url_string = url_string .. url.path
			end
			if url.query then
				url_string = url_string .. "?" .. url.query
			end
		end
	else
		url_string = nil
	end
	return url_string
end

local function new_api()
	local api
	api = {
		actions = { ["nop"] = { action = function() end, pattern = "" } },
		process = function(uri)
			for name, action in pairs(api.actions) do
				if string.match(uri, action.pattern) then
					local args = { string.match(uri, action.pattern) }
					if table.unpack then
						api.actions[name].action(table.unpack(args))
					else
						api.actions[name].action(unpack(args))
					end
					-- since we got our match we want to
					-- stop processing
					break
				end
			end
		end,
	}
	return api
end

local function request_resty(request, connection)
	local http = require("resty.http")
	local httpc = http.new()
	httpc:set_timeout(connection.timeout)

	local ok, err
	if request.scheme ~= "unix" then
		ok, err = httpc:connect(connection.address, connection.port)
		if request.scheme == "https" then
			httpc:ssl_handshake(nil, request.headers["Host"], request.ssl_verify)
		end
	else
		ok, err = httpc:connect(connection.address)
	end
	if not ok then
		return nil, err
	end

	local res, err = httpc:request(request)
	local results = {}

	if res then
		if res.has_body then
			results.body = res:read_body()
		end
		results.status = res.status
		results.headers = res.headers
		local ok, err = httpc:set_keepalive()
		return results
	end
	return nil, err
end

local function request_socket(request, timeout)
	local http, unix
	local ltn12 = require("ltn12")

	if request.scheme == "https" then
		http = require("ssl.https")
	else
		http = require("socket.http")
	end
	if request.scheme == "unix" then
		unix = require("socket.unix")
		request.create = unix
	end

	http.TIMEOUT = timeout -- this one should be in seconds
	local body = {}
	request.sink = ltn12.sink.table(body)

	if #request.body > 0 then
		request.headers["content-length"] = string.len(request.body)
		request.source = ltn12.source.string(request.body)
	end

	local result, status, headers, status_line = http.request(request)

	if result == 1 then
		return { body = table.concat(body), status = status, headers = headers }
	else
		return nil, status
	end
end

local function request(uri, options, timeout, use_luasocket)
	local timeout = timeout or 1000 -- default timeout is 1 second
	local port = 80 -- default port (will be changed to 443 if the scheme is https, also you can override this in the uri)
	local server -- the actual server to connect to
	local use_luasocket = use_luasocket or false -- an option to force using luasocket when both lua-resty-http and luasocket available

	-- These are the defaults if no options table provided in the args.
	-- Even if there is one, but, say, it lacks the method field, then GET
	-- method will be used.
	local defaults = { method = "GET", body = "", headers = {}, ssl_verify = false }

	local parsed_url = url.parse(uri)

	if parsed_url.scheme == "unix" then
		server = "unix:" .. parsed_url.socket
		--[[ 'localhost' is a reasonable default for the Host header
             when connecting to a unix socket. Anyways it can be overriden
             in the options table                  ]]
		--
		defaults.headers["Host"] = "localhost"
	else
		server = parsed_url.host
		defaults.headers["Host"] = parsed_url.host
		if parsed_url.port then
			port = parsed_url.port
		elseif parsed_url.scheme == "https" then
			port = 443
		end
	end

	defaults.scheme = parsed_url.scheme
	defaults.path = parsed_url.path
	defaults.query = parsed_url.query
	local options = std.merge_tables(defaults, options)

	if std.module_available("resty.http") and not use_luasocket then
		local results, err = request_resty(options, { port = port, timeout = timeout, address = server })
		return results, err
	elseif std.module_available("socket.http") then
		options.url = uri
		if options.scheme == "unix" then
			options.url = nil
			options.host = parsed_url.socket
		end
		local results, err = request_socket(options, timeout / 1000)
		return results, err
	end
end

_M.url = url
_M.request = request
_M.new_api = new_api

return _M
