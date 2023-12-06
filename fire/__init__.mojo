import time

from algorithm import parallelize, num_cores
from memory import memcpy, memset_zero
from memory.unsafe import bitcast
from python import Python, Dictionary
from utils.vector import InlinedFixedVector, DynamicVector

from .dodgy import DodgyString

alias __version__ = "0.0.1"
alias __version_tag__ = "pre-alpha"
alias __server__ = "Fire🔥"

alias AF_INET = 2
alias SOCK_STREAM = 1
alias SO_REUSEADDR = 2
alias SOL_SOCKET = 1
alias SO_REUSEPORT = 15
alias INADDR_ANY = 0x00000000

alias ROUTES_CAPACITY = 256
alias REQUEST_BUFFER_SIZE = 30000
alias RESPONSE_BUFFER_SIZE = 30000
alias WORKERS_PER_CORE = 10
alias HTTP_METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]
alias HOST = "0.0.0.0"
alias PORT = 8000
alias DEBUG = True


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

    # memcpy(ptr, bitcast[UInt8](s._as_ptr().load().to_int()), slen)
    memcpy(ptr, s._as_ptr().bitcast[DType.uint8](), slen)

    return external_call["write", Int, Int32, Pointer[UInt8], Int](fildes, ptr, nbyte)


fn close(fildes: Int32) -> Int32:
    return external_call["close", Int32, Int32](fildes)


fn perror(s: String):
    let slen = len(s)
    let ptr = Pointer[UInt8]().alloc(len(s))

    memcpy(ptr, s._as_ptr().bitcast[DType.uint8](), slen)

    _ = external_call["perror", UInt8, Pointer[UInt8]](ptr)


fn exit(status: Int32):
    _ = external_call["exit", UInt8, Int32](status)


struct Response:
    var status: Int
    var status_text: String
    var content: String
    var content_type: String

    fn __init__(inout self: Self):
        self.status = 200
        self.status_text = "OK"
        self.content = ""
        self.content_type = "text/plain"

    fn __init__(inout self: Self, content: String):
        self.status = 200
        self.status_text = "OK"
        self.content = content
        self.content_type = "text/plain"

    fn __copyinit__(inout self: Self, existing: Self):
        self.status = existing.status
        self.status_text = existing.status_text
        self.content = existing.content
        self.content_type = existing.content_type

    @staticmethod
    fn http_404() -> Response:
        var resp = Response()

        resp.status = 404
        resp.status_text = "Not Found"
        resp.content = "Not found"

        return resp

    @staticmethod
    fn http_500() -> Response:
        var resp = Response()
        resp.status = 500
        resp.status_text = "Internal Server Error"
        resp.content = "Internal Server Error"

        return resp

    # top level dict
    @staticmethod
    fn json_response(data: Dictionary) -> Response:
        var resp = Response()
        resp.content_type = "application/json"

        try:
            let py_json = Python.import_module("json")
            let content = py_json.dumps(data.py_object)

            resp.content = to_string_ref(str(content))
        except e:
            print("> error:", e)
            resp.content = to_string_ref("{}")

        return resp

    # top level list
    @staticmethod
    fn json_response(data: PythonObject) -> Response:
        var resp = Response()
        resp.content_type = "application/json"

        try:
            let py_json = Python.import_module("json")
            let content = py_json.dumps(data)

            resp.content = to_string_ref(str(content))
        except e:
            print("> error:", e)
            resp.content = to_string_ref("[]")

        return resp

    # with a string
    @staticmethod
    fn json_response(data: String) -> Response:
        var resp = Response()
        resp.content_type = "application/json"

        resp.content = to_string_ref(data)

        return resp

    @always_inline
    fn to_s(self: Self) -> String:
        return (
            "HTTP/1.1 "
            + String(self.status)
            + " "
            + self.status_text
            + "\nContent-Type: "
            + self.content_type
            + "\nServer: "
            + __server__
            + "/"
            + __version__
            + " ("
            + __version_tag__
            + ")\nContent-Length: "
            + String(len(self.content))
            + "\n\n"
            + self.content
        )


fn http_404() -> Response:
    return Response.http_404()


fn http_500() -> Response:
    return Response.http_500()


fn json(data: Dictionary) -> Response:
    return Response.json_response(data)


fn json(data: PythonObject) -> Response:
    return Response.json_response(data)


fn json(data: String) -> Response:
    return Response.json_response(data)


struct Request:
    var url: String
    var method: String
    var protocol_version: String

    var _qs: String
    var _data: String
    var _params: DynamicVector[DodgyString]

    var PARAMS: Dictionary
    var QS: Dictionary
    var DATA: Dictionary

    fn __init__(
        inout self,
        url: String,
        method: String,
        protocol_version: String,
    ):
        self.url = url
        self.method = method
        self.protocol_version = protocol_version

        self._qs = ""
        self._data = ""
        self._params = DynamicVector[DodgyString]()

        self.PARAMS = Python.dict()
        self.QS = Python.dict()
        self.DATA = Python.dict()

    fn get_params_dict(self) -> Dictionary:
        let res = Python.dict()

        try:
            var i = 0
            while i < len(self._params):
                res[self._params[i].to_string()] = self._params[i + 1].to_string()
                i += 2
        except e:
            print_no_newline("> error:", e)
            print("returning empty dict")

        return res

    fn get_qs_dict(self) -> Dictionary:
        let res = Python.dict()

        try:
            var i = 0
            while i < len(self._params):
                res[self._params[i].to_string()] = self._params[i + 1].to_string()
                i += 2
        except e:
            print_no_newline("> error:", e)
            print("returning empty dict")

        return res

    fn get_data_dict(self) -> Dictionary:
        let res = Python.dict()

        try:
            var i = 0
            while i < len(self._params):
                res[self._params[i].to_string()] = self._params[i + 1].to_string()
                i += 2
        except e:
            print_no_newline("> error:", e)
            print("returning empty dict")

        return res


struct Routes:
    var paths: InlinedFixedVector[StringRef, ROUTES_CAPACITY]
    var handlers: InlinedFixedVector[fn (req: Request) -> Response, ROUTES_CAPACITY]
    var size: Int

    fn __init__(inout self: Self):
        self.size = 0
        self.paths = InlinedFixedVector[StringRef, ROUTES_CAPACITY](ROUTES_CAPACITY)
        self.handlers = InlinedFixedVector[
            fn (req: Request) -> Response, ROUTES_CAPACITY
        ](ROUTES_CAPACITY)


fn to_string_ref(s: String) -> StringRef:
    let slen = len(s)
    let ptr = Pointer[UInt8]().alloc(slen)

    memcpy(ptr, s._as_ptr().bitcast[DType.uint8](), slen)

    return StringRef(ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, slen)


fn match_path(path: String, pattern: StringRef) -> Bool:
    let path_len = len(path)
    let pattern_len = len(pattern)

    # print("path:", path)
    # print("pattern:", pattern)

    if pattern_len < path_len:
        return False

    var i = 0
    var j = 0
    while i < path_len:
        if pattern[j] == "{":
            while pattern[j] != "}":
                j += 1

            while path[i] != "/" and path[i] != " ":
                i += 1

            continue

        if path[i] != pattern[j]:
            return False

        i += 1
        j += 1

    return True


fn find_handler(app: Application, path: String) raises -> fn (req: Request) -> Response:
    var i = 0

    while i < app.routes.size:
        if match_path(path, app.routes.paths[i]):
            return app.routes.handlers[i]

        i += 1

    print("Route not found")
    raise Error("Route not found")


fn find_pattern(app: Application, path: String) -> StringRef:
    var i = 0

    while i < app.routes.size:
        if match_path(path, app.routes.paths[i]):
            return app.routes.paths[i]

        i += 1

    return ""


fn load_python_modules():
    """Preload python modules to avoid loading them on the first request."""
    try:
        _ = Python.import_module("json")
    except e:
        print("> error loading python module:", e)
        exit(-1)


@always_inline
fn respond_to_client(
    client_socketfd: Int32,
    req: Request,
    handler: fn (Request) -> Response,
):
    let res = handler(req).to_s()

    _ = write(client_socketfd, res, len(res))
    _ = close(client_socketfd)


fn workers() -> Int:
    return num_cores() * WORKERS_PER_CORE


fn default_handler(request: Request) -> Response:
    return Response("")


fn wait_for_clients(
    app: Application,
    socketfd: Int32,
    inout address_sock: sockaddr,
):
    while True:
        let client_socketfd: Int32
        let not_found = http_404().to_s()
        let not_found_len = len(not_found)
        var start: Int = 0
        var bytes_received: Int32 = 0
        var sin_size = UInt32(sizeof[UInt32]())

        let buf = Pointer[UInt8].alloc(REQUEST_BUFFER_SIZE)
        client_socketfd = accept(socketfd, address_sock, sin_size)

        if client_socketfd < 0:
            print("accept")
            return

        if DEBUG:
            start = time.now()

        bytes_received = read(client_socketfd, buf, REQUEST_BUFFER_SIZE)

        let method = app.get_method(buf, REQUEST_BUFFER_SIZE)
        let path = app.get_path(buf, REQUEST_BUFFER_SIZE)
        let protocol_version = app.get_protocol_version(buf, REQUEST_BUFFER_SIZE)

        var handler: fn (Request) -> Response = default_handler
        try:
            handler = find_handler(app, path)
        except e:
            print("assigning not found handler")
            _ = write(client_socketfd, not_found, not_found_len)
            _ = close(client_socketfd)

            print("> error:", e)

            continue

        let params_data = app.get_params(
            buf, REQUEST_BUFFER_SIZE, find_pattern(app, path)
        )

        var req = Request(
            to_string_ref(path),
            to_string_ref(method),
            to_string_ref(protocol_version),
        )
        req._params = params_data
        req.PARAMS = req.get_params_dict()

        try:
            print(str(req.PARAMS.__getitem__("name")))
        except e:
            print("error:", e)

        respond_to_client(client_socketfd, req, handler)

        if DEBUG:
            var log = "[" + method + "] " + path

            let total = (time.now() - start) // 1000
            if total > 1000:
                log += " " + String(total // 1000) + " ms " + bytes_received + " bytes"
            else:
                log += " " + String(total) + " µs " + bytes_received + " bytes"

            print(log)


struct Application:
    var host: String
    var port: UInt16
    var routes: Routes

    fn __init__(inout self: Self):
        self.host = HOST
        self.port = PORT
        self.routes = Routes()

    fn route[
        path: StringLiteral
    ](inout self: Self, handler: fn (req: Request) -> Response):
        self.routes.paths.append(path)
        self.routes.handlers.append(handler)
        self.routes.size += 1

    fn run(inout self):
        load_python_modules()

        let socketfd: Int32

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
        address.sin_addr.s_addr = INADDR_ANY  # TODO: use self.host

        address.sin_port = htons(self.port)

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
            "🔥 started on http://localhost:"
            + String(self.port)
            + ", workers: "
            + String(workers())
            + " (CTRL + C to quit)"
        )

        wait_for_clients(self, socketfd, address_sock)

    @always_inline
    fn get_method(self, buf: Pointer[UInt8], buflen: Int) -> String:
        var i = 0

        # skip method
        while i < buflen:
            if buf[i] == ord(" "):
                break
            i += 1

        let ptr = Pointer[UInt8].alloc(i + 1)
        memcpy(ptr, buf, i)
        ptr.store(i + 1, 0)

        return String(ptr.bitcast[Int8](), i + 1)

    @always_inline
    fn get_path(self, buf: Pointer[UInt8], buflen: Int) -> String:
        var i = 0

        # skip method
        while i < buflen:
            if buf[i] == ord(" "):
                break
            i += 1

        i += 1
        var j = i

        # skip path
        while j < buflen:
            if buf[j] == ord(" "):
                break
            j += 1

        # write path
        let ptr = Pointer[UInt8].alloc(j - i + 1)
        memcpy(ptr, buf.offset(i), j - i)
        ptr.store(j - i + 1, 0)

        return String(ptr.bitcast[Int8](), j - i + 1)

    @always_inline
    fn get_protocol_version(self, buf: Pointer[UInt8], buflen: Int) -> String:
        var i = 0

        # skip method
        while i < buflen:
            if buf[i] == ord(" "):
                break
            i += 1

        i += 1

        # skip path
        while i < buflen:
            if buf[i] == ord(" "):
                break
            i += 1

        i += 1
        var j = i

        # skip protocol version
        while j < buflen:
            if buf[j] == ord("\n"):
                break
            j += 1

        # write protocol version
        let ptr = Pointer[UInt8].alloc(j - i)
        memcpy(ptr, buf.offset(i), j - i)

        return String(ptr.bitcast[Int8](), j - i)

    fn get_params(
        self, buf: Pointer[UInt8], buflen: Int, pattern: StringRef
    ) -> DynamicVector[DodgyString]:
        let pattern_string = String(pattern)
        var res = DynamicVector[DodgyString]()
        let path = self.get_path(buf, buflen)

        var i = 0
        var j = 0
        while i < len(path):
            if (
                path[i] == " "
                or path[i] == "?"
                or ord(path[i]) < 31
                or ord(path[i]) > 128
            ):
                break

            if pattern[j] == "{":
                let name_start = j + 1

                while pattern[j] != "}":
                    j += 1

                let name_end = j
                let name = pattern_string[name_start:name_end]

                res.push_back(to_string_ref(name))

                let value_start = i
                while (
                    path[i] != "/"
                    and path[i] != " "
                    and ord(path[i]) > 31
                    and ord(path[i]) < 128
                ):
                    i += 1
                let value_end = i
                let value = path[value_start:value_end]
                res.push_back(to_string_ref(value))

            if (
                path[i] == " "
                or path[i] == "?"
                or ord(path[i]) < 31
                or ord(path[i]) > 128
            ):
                break

            i += 1
            j += 1

        return res
