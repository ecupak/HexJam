class Point {
    x { _x } 
    x=(value) { 
        _x = value
        _q = value
    }

    y { _y }
    y=(value) {
        _y = value
        _r = value
    }
    
    z { _z }
    z=(value) { 
        _z = value
        _s = value
    }
    
    q { _q }
    q=(value) { 
        _q = value
        _x = value
    }

    r { _r }
    r=(value) {
        _r = value
        _y = value
    }

    s { _s }
    s=(value) { 
        _s = value
        _z = value
    }

    construct new(first, second) {
        _x = first
        _q = first

        _y = second
        _r = second

        _z = 0
        _s = 0
    }

    construct triple(first, second, third) {
        _x = first
        _q = first

        _y = second
        _r = second

        _z = third
        _s = third
    }
}