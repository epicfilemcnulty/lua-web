local web = require("src/web")

describe("Test url parsing & building:", function()

  it("test #plain #URL", function()

    local testUrl = "http://12factor.com/some/article?paged=true"
    local expected = { scheme = 'http', host = '12factor.com', path = '/some/article', query = 'paged=true' }
    local actual = web.url.parse(testUrl)
    assert.are.same(expected, actual) 

  end)

  it("test #URL with port", function()

    local testUrl = "https://12factor.com:8443/some/other/article?paged=false&foo=bar"
    local expected = { scheme = 'https', host = '12factor.com', port = 8443, path = '/some/other/article', query = 'paged=false&foo=bar' }
    local actual = web.url.parse(testUrl)
    assert.are.same(expected, actual) 

  end)

  it("test #URL with #unix socket", function()

    local testUrl = "unix:/var/run/docker.sock:/containers/list?json=true"
    -- web.url.parse should append "http:" to the path
    local expected = { scheme = 'unix', socket = '/var/run/docker.sock', path = 'http:/containers/list', query = 'json=true' }
    local actual = web.url.parse(testUrl)
    assert.are.same(expected, actual) 

  end)

  it("test plain #URL building", function ()
    
    local testUrl = "http://sub.example-example.com:8443/id/1234/get?paged=true"
    local expected = testUrl
    local parsedUrl = web.url.parse(testUrl)
    local actual = web.url.build(parsedUrl)
    assert.are.equal(expected, actual)
  
  end)

  it("test unix socket #URL building", function ()
    
    local testUrl = "unix:/var/run/docker.sock:/containers/list?json=true"
    local expected = testUrl
    local parsedUrl = web.url.parse(testUrl)
    local actual = web.url.build(parsedUrl)
    assert.are.equal(expected, actual)

  end) 

end)


