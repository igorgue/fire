from fire import Request, Response, app, route as r


fn index(request: Request) -> Response:
    return Response()


fn posts(request: Request) -> Response:
    return Response()


fn main() raises:
    r["/"](index)
    r["/posts"](posts)

    app.run()
