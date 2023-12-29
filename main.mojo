import time

from fire import json, Request, Response, Application


fn index(request: Request) -> Response:
    return Response("hello world")


# fn get_post(request: Request) -> Response:
#     return json(request.PARAMS)


fn main():
    var app = Application()

    app.route["/"](index)

    app.run()
