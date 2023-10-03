from fire import Request, Response, app, route as r


fn index(request: Request) -> Response:
    return Response("at index")


fn posts(request: Request) -> Response:
    return Response("at posts")


fn get_post(request: Request) -> Response:
    return Response.json_response(request.params_dict())


fn main():
    r["/"](index)
    r["/posts"](posts)
    r["/posts/{id}"](get_post)

    app.run()
