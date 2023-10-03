from fire import Request, Response, app, route as r, json, http_500


fn index(request: Request) -> Response:
    return Response("at index")


fn posts(request: Request) -> Response:
    return Response("at posts")


fn get_post(request: Request) -> Response:
    return json(request.PARAMS)


fn see_500(request: Request) -> Response:
    return http_500()


fn main():
    r["/"](index)
    r["/posts"](posts)
    r["/posts/{id}"](get_post)
    r["/500"](see_500)

    app.run()
