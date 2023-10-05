import time

from fire import app, json, r, Request, Response


fn index(request: Request) -> Response:
    return Response("hello world")


fn get_post(request: Request) -> Response:
    return json(request.PARAMS)


fn main():
    r["/"](index)
    r["/posts/{id}"](get_post)

    app.run()
