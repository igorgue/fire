# fire 🔥

A web framework written in Mojo.

**NOTE**: This is a work in progress. It is not ready for production use.

## example

```python
from fire import Request, Response, app, route as r


fn index(request: Request) -> Response:
    # TODO: add response attributes
    return Response()


fn posts(request: Request) -> Response:
    return Response()


fn main():
    r["/"](index)
    r["/posts"](posts)

    app.run()
```
