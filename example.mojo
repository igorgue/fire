from fire import Request, Response, app, route as r


fn index(request: Request) -> Response:
    return Response("at index")


fn posts(request: Request) -> Response:
    return Response("at posts")


fn main():
    r["/"](index)
    r["/posts"](posts)

    app.run()
