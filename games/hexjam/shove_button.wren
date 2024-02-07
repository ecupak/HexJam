
class MatchType {
    static Q { 0 }
    static R { 1 }
    static S { 2 }
}

class ShoveButton {
    static radius {__radius}

    position {_position}
    
    match_type {_match_type}
    
    match_value {_match_value}

    is_ascending {_is_ascending}

    sort_type {_sort_type}
    
    is_hovered {_is_hovered}
    is_hovered=(value) {
        _is_hovered = value
    }

    is_visible {_is_visible}
    is_visible=(value) {
        _is_visible = value
    }

    static init() {
        __radius = 10
    }

    construct new (x, y, direction, match_type, match_value) {
        _position = Point.new(x, y)
        _match_type = match_type
        _match_value = match_value
        _is_hovered = false
        _is_visible = false

        _is_ascending = (direction == 2 || direction == 3 || direction == 4)
        _sort_type = (match_type == MatchType.Q ? MatchType.R : MatchType.Q)
    }
}

import "Point" for Point