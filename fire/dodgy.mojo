@value
@register_passable("trivial")
struct DodgyString(CollectionElement):
    """
    A string that is dodgy because it is not null-terminated.
    """

    var data: Pointer[Int8]
    var size: Int

    fn __init__(value: StringLiteral) -> DodgyString:
        let l = len(value)
        let s = String(value)
        let p = Pointer[Int8].alloc(l)

        for i in range(l):
            p.store(i, s._buffer[i])

        return DodgyString(p, l)

    fn __init__(value: String) -> DodgyString:
        let l = len(value)
        let p = Pointer[Int8].alloc(l)

        for i in range(l):
            p.store(i, value._buffer[i])

        return DodgyString(p, l)

    fn __init__(value: StringRef) -> DodgyString:
        let l = len(value)
        let s = String(value)
        let p = Pointer[Int8].alloc(l)

        for i in range(l):
            p.store(i, s._buffer[i])

        return DodgyString(p, l)

    fn __eq__(self, other: DodgyString) -> Bool:
        if self.size != other.size:
            return False

        for i in range(self.size):
            if self.data.load(i) != other.data.load(i):
                return False

        return True

    fn __ne__(self, other: DodgyString) -> Bool:
        return not self.__eq__(other)

    fn to_string(self) -> String:
        let ptr = Pointer[Int8]().alloc(self.size + 1)

        memcpy(ptr, self.data, self.size)
        memset_zero(ptr.offset(self.size), 1)

        return String(ptr, self.size)

    fn to_string_ref(self) -> StringRef:
        let ptr = Pointer[Int8]().alloc(self.size + 1)

        memcpy(ptr, self.data, self.size)
        memset_zero(ptr.offset(self.size), 1)

        return StringRef(
            ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, self.size
        )
