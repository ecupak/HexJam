import "xs" for Render
import "xs_math" for Math
import "hex" for Hex, Point

class HexMap {
    static range { __range }

    static init_as_flat_top(radius, range) {
        __outer_r   = radius
        __inner_r   = radius * 0.9
        __width     = radius * 2
        __height    = radius * (3).sqrt

        __range     = range
    }


    static draw_hex(hex) {
        var hex_origin = this.get_hex_origin(hex.position.q, hex.position.r)

        var angle_increment = (Math.pi * 2) / 6
        var angle = angle_increment

        var x_start = hex_origin.x + angle.cos * __inner_r
        var y_start = hex_origin.y + angle.sin * __inner_r

        if (hex.is_hovered) {
            Render.setColor(0x00FF00FF)
        } else {
            Render.setColor(0xFF00FFFF)
        }

        for (sides in 1..6) {
            angle = angle + angle_increment

            var x_end = hex_origin.x + angle.cos * __inner_r
            var y_end = hex_origin.y + angle.sin * __inner_r
        
            Render.begin(Render.lines)
            Render.vertex(x_start, y_start)
            Render.vertex(x_end, y_end)
            Render.end()

            x_start = x_end
            y_start = y_end   
        }

        // Debug
        Render.setColor(0x00FF00FF)
        Render.shapeText("%(hex.position.q)", hex_origin.x - 5, hex_origin.y + 15, 1)
        Render.setColor(0x00FFFFFF)
        Render.shapeText("%(hex.position.r)", hex_origin.x + 5, hex_origin.y - 4, 1)
        Render.setColor(0xFFFFFFFF)
        Render.shapeText("%(hex.id)", hex_origin.x - 15, hex_origin.y - 4, 1)
    }


    static get_hex_origin(q, r) {
        var x = __outer_r * (3/2 * q)
        var y = __outer_r * ((3).sqrt / 2 * q + (3).sqrt * r)

        return Point.new(x, y)
    }
}