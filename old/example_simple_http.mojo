from fire import (
    accept,
    bind,
    close,
    htons,
    listen,
    sockaddr,
    setsockopt,
    sockaddr_in,
    socket,
    read,
    write,
    AF_INET,
    INADDR_ANY,
    SOCK_STREAM,
    SOL_SOCKET,
    SO_REUSEADDR,
    SO_REUSEPORT,
)

alias PORT = 8000


fn main():
    let socketfd: Int32
    let client_socketfd: Int32

    var address = sockaddr_in()
    var opt: UInt8 = SO_REUSEADDR
    let addrlen = sizeof[sockaddr_in]()

    let hello = "HTTP/1.1 200 OK\nContent-Type: text/plain\nContent-Length: 12\n\nHello world!"

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
    address.sin_addr.s_addr = INADDR_ANY
    address.sin_port = htons(PORT)

    var address_sock = Pointer[sockaddr_in].address_of(address).bitcast[
        sockaddr
    ]().load()
    if bind(socketfd, address_sock, addrlen) < 0:
        print("bind failed")
        return

    if listen(socketfd, 10) < 0:
        print("listen")
        return

    print("Started 🔥 on http://localhost:" + String(PORT) + " (CTRL + C to quit)")

    while True:
        print("> waiting for new connection...")

        var sin_size = UInt32(sizeof[UInt32]())
        client_socketfd = accept(socketfd, address_sock, sin_size)

        if client_socketfd < 0:
            print("accept")
            return

        let buf = Pointer[UInt8].alloc(30000)
        _ = read(client_socketfd, buf, 30000)
        _ = write(client_socketfd, hello, len(hello))

        print("> hello sent")
        _ = close(client_socketfd)
