from fire import Request, Response, app, route as r


fn index(request: Request) -> Response:
    return Response("at index")


fn posts(request: Request) -> Response:
    return Response("at posts")


fn get_post(request: Request) -> Response:
    return Response("at get post")


fn main():
    r["/"](index)
    r["/posts"](posts)
    r["/posts/{id}"](get_post)

    app.run()
