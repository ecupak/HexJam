
class MatchType {
    static Q { 0 }
    static R { 1 }
    static S { 2 }
}

class ShoveButton {
    construct new (x, y, match_type, match_value) {
        _position = Position.new(x, y)
        _match_type = match_type
        _match_value = match_value
    }
}