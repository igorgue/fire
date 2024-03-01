import time

from fire import json, Request, Response, Application


fn index(request: Request) -> Response:
    return Response("burn baby burn 🔥!")


fn main():
    var app = Application()

    app.route["/"](index)

    app.run()
