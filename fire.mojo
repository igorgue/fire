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


@value
@register_passable("trivial")
struct Application:
    var host: StringRef
    var port: UInt16

    fn __init__() -> Self:
        return Self {host: "0.0.0.0", port: 8000}

    fn run(self) -> None:
        print("Running server on", self.host, "port", self.port)


var app = Application()


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
