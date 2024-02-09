
class HexMath {
    static init(range) {
        __range = range
    }

    static key(q, r) { (q + __range) + ((r + __range) * 1000) }
}