class Point {
    x { _x }
    y { _y }
    q { _q }
    r { _r }

    x=(value) { 
        _x = value
        _q = value
    }

    y=(value) {
        _y = value
        _r = value
    }
    
    q=(value) { 
        _q = value
        _x = value
    }

    r=(value) {
        _r = value
        _y = value
    }

    construct new(first, second) {
        _x = first
        _q = first

        _y = second
        _r = second
    }
}