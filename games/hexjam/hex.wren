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

    is_highlighted { _is_highlighted }
    is_highlighted=(value) {
        _is_highlighted = value
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

    is_visible { _is_visible }
    is_visible=(value) {
        _is_visible = value
    }

    occupants { _occupants }
    occupants=(value) {
        _occupants = value
    }


    construct new(id, position, terrain) {
        _id = id
        _position = position
        _terrain = terrain

        _is_hovered = false
        _is_in_stack = false
        _is_goal = false
        _is_visible = 1
        _occupants = []
    }

    static init(outer_radius) {
        __outer_radius = outer_radius
        __inner_radius = outer_radius * 0.9
    }


    moved() {
        if (_occupants.count > 0) {
            _occupants[0].setPosition(_position)
        }
    }


    reset() {
        _is_highlighted = false
        _is_hovered = false
        _is_in_stack = false
        _occupant = []
    }
}

import "point" for Point