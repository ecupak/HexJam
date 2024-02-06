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

class Hex {
    id { _id }
    position { _position }
    is_hovered { _is_hovered }

    id=(value) {
        _id = value
    }

    position=(value) { 
        _position = value
    }

    is_hovered=(value) {
        _is_hovered = value
    }

    construct new(id, position) {
        _id = id
        _position = position
        _is_hovered = false
    }
}