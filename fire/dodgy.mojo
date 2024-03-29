from .list_iterator import ListIterator


@value
@register_passable("trivial")
struct DodgyString(CollectionElement):
    """
    A string that is dodgy because it is not null-terminated.
    """

    var data: Pointer[Int8]
    var size: Int

    fn __init__(value: StringLiteral) -> DodgyString:
        var l = len(value)
        var s = String(value)
        var p = Pointer[Int8].alloc(l)

        for i in range(l):
            p.store(i, s._buffer[i])

        return DodgyString(p, l)

    fn __init__(value: String) -> DodgyString:
        var l = len(value)
        var p = Pointer[Int8].alloc(l)

        for i in range(l):
            p.store(i, value._buffer[i])

        return DodgyString(p, l)

    fn __init__(value: StringRef) -> DodgyString:
        var l = len(value)
        var s = String(value)
        var p = Pointer[Int8].alloc(l)

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

    fn __iter__(self) -> ListIterator[Int8]:
        return ListIterator[Int8](self.data, self.size)

    fn to_string(self) -> String:
        var ptr = Pointer[Int8]().alloc(self.size + 1)

        memcpy(ptr, self.data, self.size)
        memset_zero(ptr.offset(self.size), 1)

        return String(ptr, self.size)

    fn to_string_ref(self) -> StringRef:
        var ptr = Pointer[Int8]().alloc(self.size + 1)

        memcpy(ptr, self.data, self.size)
        memset_zero(ptr.offset(self.size), 1)

        return StringRef(
            ptr.bitcast[__mlir_type.`!pop.scalar<si8>`]().address, self.size
        )
