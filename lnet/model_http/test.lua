print(http.req.uri, http.req.content)

http.resp.code = 401
http.resp.desc = "Unauthorized"
http.resp.headers["Content-Type"] = "text/plain"
http.resp.content = "this is a test"

