class Hex {
    static outer_radius { __outer_radius }
    static inner_radius { __inner_radius }
    
    id { _id }
    id=(value) {
        _id = value
    }

    position { _position }
    position=(value) { 
        _position = value
    }

    is_hovered { _is_hovered }
    is_hovered=(value) {
        _is_hovered = value
    }

    construct new(id, position) {
        _id = id
        _position = position
        _is_hovered = false
    }

    static init_as_flat_top(outer_radius) {
        __outer_radius = outer_radius
        __inner_radius = outer_radius * 0.9
    }
}

import "point" for Point