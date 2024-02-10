import "xs" for Render

class Player {
    hex_position { _hex_position }
    hex_position=(value) { 
        _hex_position = value
    }

    pixel_position { _pixel_position }
    pixel_position=(value) { 
        _pixel_position = value
    }

    current_hex { _current_hex }
    current_hex=(value) {
        _current_hex = value
    }


    construct new() {
        // empty
    }


    update(dt) {
        // empty
    }


    render() {
        Render.setColor(0xFFFF00FF)
        Render.square(pixel_position.x, pixel_position.y, 10)
    }


    setPosition(hex_position) {
        _hex_position = hex_position
        _pixel_position = HexMap.getPixelPositionFromHex(hex_position)
    }
}


import "hex_map" for HexMap