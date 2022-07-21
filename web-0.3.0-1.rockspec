package = "web"
 version = "0.3.0-1"
 source = {
    url = "git+https://github.com/epicfilemcnulty/lua-web.git",
    tag = "v0.3.0"
 }
 description = {
    summary = "Module for working with web requests",
    detailed = [[
        Lua module to make HTTP requests easy way + a simple
        route parser (poor man's API). Under the hood this module
        uses either lua-resty-http (if available) or luasocket module 
        to make HTTP(s) requests. Since only one of these modules
        is used, they are not mentioned in the dependencies for this
        rock, and one of them must be already installed. If you
        want to make HTTPS requests using luasocket you will 
        also have to have luasec module installed.
    ]],
    homepage = "https://github.com/epicfilemcnulty/lua-web",
    license = "CC0 1.0"
 }
 dependencies = {
    "lua >= 5.1",
    "deviant >= 2.2.0"
 }
 build = {
    type = "builtin",
    modules = {
       web = "src/web.lua"
    }
 }
