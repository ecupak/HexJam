class ShoveButton {
    static radius { 10 }

    position { _position }
    
    match_axis { _match_axis }
    
    match_value { _match_value }

    sort_ascending { _sort_ascending }

    sort_axis { _sort_axis }
    
    is_hovered { _is_hovered }
    is_hovered=(value) {
        _is_hovered = value
    }

    construct new (x, y, direction, match_axis, match_value) {
        _position = Point.new(x, y)
        _match_axis = match_axis
        _match_value = match_value
        _is_hovered = false

        _sort_ascending = (direction == 2 || direction == 3 || direction == 4)
        _sort_axis = (match_axis == Axis.Q ? Axis.R : Axis.Q)
    }
}

import "Point" for Point, Axis