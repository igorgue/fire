alias __version__ = "0.0.1"
alias __version_tag__ = "pre-alpha"
alias AF_INET = 2
alias SOCK_STREAM = 1
alias SO_REUSEADDR = 2
alias SOL_SOCKET = 1
alias SO_REUSEPORT = 15
alias INADDR_ANY = 0x00000000


@value
@register_passable("trivial")
struct in_addr:
    var s_addr: UInt32


@value
@register_passable("trivial")
struct sockaddr_in:
    var sin_family: UInt16
    var sin_port: UInt16
    var sin_addr: in_addr
    var sin_zero: StaticTuple[8, UInt8]

    fn __init__() -> Self:
        return Self {
            sin_family: 0,
            sin_port: 0,
            sin_addr: in_addr(0),
            sin_zero: StaticTuple[8, UInt8](0),
        }


@value
@register_passable("trivial")
struct sockaddr:
    var sa_family: UInt16
    var sa_data: StaticTuple[14, UInt8]


fn socket(domain: Int32, socket_type: Int32, protocol: Int32) -> Int32:
    return external_call["socket", Int32, Int32, Int32, Int32](
        domain, socket_type, protocol
    )


fn bind(socket: Int32, inout address: sockaddr, address_len: UInt32) -> Int32:
    return external_call[
        "bind", Int32, Int32, Pointer[sockaddr], UInt32  # FnName, RetType  # Args
    ](socket, Pointer[sockaddr].address_of(address), address_len)


fn listen(socket: Int32, backlog: Int32) -> Int32:
    return external_call["listen", Int32, Int32, Int32](socket, backlog)


fn accept(socket: Int32, inout address: sockaddr, inout address_len: UInt32) -> Int32:
    return external_call["accept", Int32, Int32, Pointer[sockaddr], Pointer[UInt32]](
        socket,
        Pointer[sockaddr].address_of(address),
        Pointer[UInt32].address_of(address_len),
    )


fn setsockopt(
    socket: Int32,
    level: Int32,
    option_name: Int32,
    inout option_value: UInt8,
    option_len: UInt32,
) -> Int32:
    return external_call[
        "setsockopt", Int32, Int32, Int32, Int32, Pointer[UInt8], UInt32
    ](socket, level, option_name, Pointer[UInt8].address_of(option_value), option_len)


fn htons(hostshort: UInt16) -> UInt16:
    return external_call["htons", UInt16, UInt16](hostshort)


fn read(fildes: Int32, buf: Pointer[UInt8], nbyte: Int) -> Int32:
    return external_call["read", Int, Int32, Pointer[UInt8], Int](fildes, buf, nbyte)


fn write(fildes: Int32, s: String, nbyte: Int) -> Int32:
    let slen = len(s)
    let ptr = Pointer[UInt8]().alloc(slen)

    memcpy(ptr, s._buffer.data.bitcast[UInt8](), slen)

    return external_call["write", Int, Int32, Pointer[UInt8], Int](fildes, ptr, nbyte)


fn close(fildes: Int32) -> Int32:
    return external_call["close", Int32, Int32](fildes)


fn perror(s: String):
    let ptr = Pointer[Int8]().alloc(len(s))

    memcpy(ptr, s._buffer.data.bitcast[Int8](), len(s))

    _ = external_call["perror", UInt8, Pointer[Int8]](ptr)


fn exit(status: Int32):
    _ = external_call["exit", UInt8, Int32](status)


alias REQUEST_BUFFER_SIZE = 30000
alias RESPONSE_BUFFER_SIZE = 30000
alias HTTP_METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]
alias HOST = "0.0.0.0"
alias PORT = 8000


@value
@register_passable("trivial")
struct Response:
    var status: Int
    var status_text: StringRef
    var content: StringRef

    fn __init__() -> Self:
        return Self {status: 200, status_text: "OK", content: ""}

    fn __init__(content: String) -> Self:
        return Self {status: 200, status_text: "OK", content: to_string_ref(content)}

    @staticmethod
    fn http_404() -> Response:
        var resp = Response()
        resp.status = 404
        resp.status_text = "Not Found"
        resp.content = "Not found"

        return resp

    fn to_string(self) -> String:
        return (
            "HTTP/1.1 "
            + String(self.status)
            + " "
            + self.status_text
            + "\nContent-Type: text/plain\nServer: Fire🔥/"
            + __version__
            + " ("
            + __version_tag__
            + ")\nContent-Length: "
            + String(len(self.content))
            + "\n\n"
            + self.content
        )


@value
@register_passable("trivial")
struct Request:
    var url: StringRef
    var method: StringRef
    var query_string: StringRef


alias ROUTES_CAPACITY = 256


struct Routes:
    var paths: InlinedFixedVector[ROUTES_CAPACITY, StringRef]
    var handlers: InlinedFixedVector[ROUTES_CAPACITY, fn (req: Request) -> Response]
    var size: Int

    fn __init__(inout self: Self):
        self.size = 0
        self.paths = InlinedFixedVector[ROUTES_CAPACITY, StringRef](ROUTES_CAPACITY)
        self.handlers = InlinedFixedVector[
            ROUTES_CAPACITY, fn (req: Request) -> Response
        ](ROUTES_CAPACITY)


var routes = Routes()


fn route[path: StringLiteral](handler: fn (req: Request) -> Response):
    routes.paths.append(path)
    routes.handlers.append(handler)
    routes.size += 1


fn to_string_ref(s: String) -> StringRef:
    let slen = len(s)
    let ptr = Pointer[Int8]().alloc(slen)

    memcpy(ptr, s._buffer.data.bitcast[Int8](), slen)

    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, slen)


fn find_handler(path: String) raises -> fn (req: Request) -> Response:
    let path_ref = to_string_ref(path)
    var i = 0

    while i < routes.size:
        print("> checking path:", routes.paths[i])
        print("> checking path_ref:", path_ref)
        print("> checking path len:", len(routes.paths[i]))
        print("> checking path_ref len:", len(path_ref))
        if routes.paths[i] == path_ref:
            print("> found handler for path:", path)
            return routes.handlers[i]
        i += 1

    raise Error("Route not found")


@value
@register_passable("trivial")
struct Application:
    var host: StringRef
    var port: UInt16

    fn __init__() -> Self:
        return Self {host: HOST, port: PORT}

    fn run(self) -> None:
        let socketfd: Int32
        let client_socketfd: Int32

        var address = sockaddr_in()
        var opt: UInt8 = SO_REUSEADDR
        let addrlen = sizeof[sockaddr_in]()

        socketfd = socket(AF_INET, SOCK_STREAM, 0)
        if socketfd < 0:
            print("socket creation failed")
            return

        if (
            setsockopt(
                socketfd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, opt, sizeof[Int32]()
            )
            < 0
        ):
            print("setsockopt")
            return

        address.sin_family = AF_INET
        address.sin_addr.s_addr = INADDR_ANY  # TODO: use app.host
        address.sin_port = htons(app.port)

        var address_sock = Pointer[sockaddr_in].address_of(address).bitcast[
            sockaddr
        ]().load()
        if bind(socketfd, address_sock, addrlen) < 0:
            print("bind failed")
            return

        if listen(socketfd, 10) < 0:
            print("listen")
            return

        print(
            "Started 🔥 on http://localhost:" + String(app.port) + " (CTRL + C to quit)"
        )

        while True:
            print("> waiting for new connection...")

            var sin_size = UInt32(sizeof[UInt32]())
            client_socketfd = accept(socketfd, address_sock, sin_size)

            if client_socketfd < 0:
                print("accept")
                return

            let buf = Pointer[UInt8].alloc(30000)
            _ = read(client_socketfd, buf, 30000)

            let method = self.get_method(buf, 30000)
            let path = self.get_path(buf, 30000)
            let protocol_version = self.get_protocol_version(buf, 30000)

            try:
                let handler = find_handler(path)

                # print("> method:", method)
                # print("> path:", path)
                # print("> protocol_version:", protocol_version)

                let req = Request(to_string_ref(path), to_string_ref(method), "")
                let res = handler(req).to_string()

                _ = write(client_socketfd, res, len(res))
                _ = close(client_socketfd)

                print("> response sent")
            except e:
                let res = Response.http_404().to_string()

                _ = write(client_socketfd, res, len(res))
                _ = close(client_socketfd)

                print("> error:", e.value)

    @always_inline
    fn get_method(self, buf: Pointer[UInt8], len: Int) -> String:
        var i = 0

        # skip method
        while i < len:
            if buf[i] == ord(" "):
                break
            i += 1

        let ptr = Pointer[UInt8].alloc(i)
        memcpy(ptr, buf, i)

        return String(ptr.bitcast[Int8](), i)

    @always_inline
    fn get_path(self, buf: Pointer[UInt8], len: Int) -> String:
        var i = 0

        # skip method
        while i < len:
            if buf[i] == ord(" "):
                break
            i += 1

        i += 1
        var j = i

        # skip path
        while j < len:
            if buf[j] == ord(" "):
                break
            j += 1

        # write path
        let ptr = Pointer[UInt8].alloc(j - i)
        memcpy(ptr, buf.offset(i), j - i)

        return String(ptr.bitcast[Int8](), j - i)

    @always_inline
    fn get_protocol_version(self, buf: Pointer[UInt8], len: Int) -> String:
        var i = 0

        # skip method
        while i < len:
            if buf[i] == ord(" "):
                break
            i += 1

        i += 1

        # skip path
        while i < len:
            if buf[i] == ord(" "):
                break
            i += 1

        i += 1
        var j = i

        # skip protocol version
        while j < len:
            if buf[j] == ord("\n"):
                break
            j += 1

        # write protocol version
        let ptr = Pointer[UInt8].alloc(j - i)
        memcpy(ptr, buf.offset(i), j - i)

        return String(ptr.bitcast[Int8](), j - i)


var app = Application()
