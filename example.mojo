from fire import Request, Response, app, route as r


fn index(request: Request) -> Response:
    return Response("at index")


fn posts(request: Request) -> Response:
    return Response("at posts")


fn get_post(request: Request) -> Response:
    var i = 0

    # while i < len(request.params):
    #     print("name:", request.params[i])
    #     print("value:", request.params[i + 1])
    #
    #     i += 2

    return Response("at get post")


fn main():
    r["/"](index)
    r["/posts"](posts)
    r["/posts/{id}"](get_post)

    app.run()
