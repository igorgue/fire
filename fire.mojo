@value
@register_passable
struct Application:
    var host: StringRef
    var port: UInt16

    fn __init__() -> Self:
        return Self {
            host: "0.0.0.0",
            port: 8000,
        }

    fn __init__(host: StringRef, port: UInt16) -> Self:
        return Self {
            host: host,
            port: port,
        }

    fn run(self) -> None:
        print("Running server on", self.host, "port", self.port)


@value
@register_passable
struct Response:
    var status: Int

    fn __init__() -> Self:
        return Self {status: 200}


struct Request:
    pass


alias CAPACITY = 256

var paths = DynamicVector[StringLiteral](CAPACITY)
var handlers = DynamicVector[fn (req: Request) -> Response](CAPACITY)
var size: UInt8 = 0


fn route[path: StringLiteral](handler: fn (req: Request) -> Response):
    paths.push_back(path)
    handlers.push_back(handler)
    size += 1
