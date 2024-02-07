import "xs" for Render

class Player {
    position { _position }

    position=(value) { 
        _position = value
    }

    current_hex { _current_hex }
    current_hex=(value) {
        _current_hex = value
    }

    construct new(position) {
        _position = position
    }


    update(dt) {
        _position = _current_hex.position
    }


    render() {
        Render.setColor(0xFFFF00FF)

        var origin = HexMap.get_hex_origin_xy(position.q, position.r)
        Render.square(origin.x, origin.y, 10)
    }
}

import "hex_map" for HexMap