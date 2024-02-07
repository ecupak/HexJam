class Terrain {
    static Grass { 0 }
    static Forest { 1 }
    static Mountain { 2 }
    static Water { 4 }
}

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

    is_in_stack { _is_in_stack }
    is_in_stack=(value) {
        _is_in_stack = value
    }

    terrain { _terrain }
    terrain=(value) {
        _terrain = value
    }

    is_goal { _is_goal }
    is_goal=(value) {
        _is_goal = value
    }

    construct new(id, position, terrain) {
        _id = id
        _position = position
        _terrain = terrain

        _is_hovered = false
        _is_in_stack = false
        _is_goal = false
    }

    static init_as_flat_top(outer_radius) {
        __outer_radius = outer_radius
        __inner_radius = outer_radius * 0.9
    }
}

import "point" for Point