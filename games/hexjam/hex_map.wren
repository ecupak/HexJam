import "xs" for Input, Render
import "xs_math" for Math

class HexMap {
    range{ __range }

    static init(range) {
        __range = range
        __hexes = {}
        __shove_buttons = []        
        __directions = [ Point.new(1, -1), Point.new(0, -1), Point.new(-1, 0), Point.new(-1, 1), Point.new(0, 1), Point.new(1, 0) ]
    }


    static clearLevel() {
        __hexes.clear()
    }


    static setupLevel() {
        clearLevel()

        var hexCount = 0
        
        // Place hexagons.
        for (q in -__range..__range) {

            var min_range = (-__range).max(-q - __range)
            var max_range = __range.min(-q + __range)
            
            for (r in min_range..max_range) {            
                __hexes[key(q, r)] = Hex.new(hexCount, Point.new(q, r))        
                hexCount = hexCount + 1
            }
        }

        // Check each hex on outer ring to determine where to place shove buttons.
        var q = 0
        var r = __range        
        var hex = __hexes[key(q, r)]

        for (count in 0..__range) {
            // Store the direction of vacancies and occupancies of surrounding hexes.
            var vacancies = {}
            var occupancies = {}

            for (direction in 0..5) {
                var neighbor_position = this.get_neighbor_position(hex, direction)
                
                if (__hexes.containsKey(key(neighbor_position))) {
                    occupancies[direction] = neighbor_position
                } else {
                    vacancies[direction] = neighbor_position
                }
            }

            // If the opposing sides both have a neighbor, this vacant side can be pushed.
            for (position in vacancies) {
                var key1 = (position.key + 2) % 6
                var key2 = (position.key + 4) % 6

                if (occupancies.containsKey(key1) && occupancies.containsKey(key2)) {
                    var hex_origin = this.get_hex_origin_xy(hex.position.q, hex.position.r)

                    var angle_increment = (Math.pi * 2) / 6
                    var angle = (angle_increment * 0.5) + (angle_increment * position.key) 

                    var x = hex_origin.x + angle.cos * Hex.outer_radius
                    var y = hex_origin.y + angle.sin * Hex.outer_radius

                    if (position.key == 0 || position.key == 3) {
                        __shove_buttons.add(ShoveButton.new(x, y, MatchValue.R, position.value.r))
                    } else if (position.key == 1 || position.key == 4) {
                        __shove_buttons.add(ShoveButton.new(x, y, MatchValue.Q, position.value.q))
                    } else {
                        __shove_buttons.add(ShoveButton.new(x, y, MatchValue.S, (-position.value.q) - position.value.r))
                    }
                }
            }
        }
    }


    static update(dt) {
        var x = Input.getMouseX()
        var y = Input.getMouseY()

        var initial_q = (x * 2 / 3) / Hex.outer_radius
        var initial_r = ((x * -1 / 3) + (y * (3).sqrt / 3)) / Hex.outer_radius
        var initial_s = -initial_q - initial_r

        var rounded_q = initial_q.round
        var rounded_r = initial_r.round
        var rounded_s = initial_s.round

        var delta_q = (initial_q - rounded_q).abs
        var delta_r = (initial_r - rounded_r).abs
        var delta_s = (initial_s - rounded_s).abs

        if (delta_q > delta_r && delta_q > delta_s) {
            rounded_q = -rounded_r - rounded_s
        } else if (delta_r > delta_s) { 
            rounded_r = -rounded_q - rounded_s
        } else {
            rounded_s = -rounded_q - rounded_r
        }

        var key = key(rounded_q, rounded_r)
        if (__hexes.containsKey(key)) {
            __hexes[key].is_hovered = true
        }
    }
    

    static render() {
        for (hex in __hexes) {
            draw_hex(hex.value)
            hex.value.is_hovered = false
        }
    }


    static draw_hex(hex) {
        var hex_origin = this.get_hex_origin_xy(hex.position.q, hex.position.r)

        var angle_increment = (Math.pi * 2) / 6
        var angle = angle_increment

        var x_start = hex_origin.x + angle.cos * Hex.inner_radius
        var y_start = hex_origin.y + angle.sin * Hex.inner_radius

        if (hex.is_hovered) {
            Render.setColor(0x00FF00FF)
        } else {
            Render.setColor(0xFF00FFFF)
        }

        for (sides in 1..6) {
            angle = angle + angle_increment

            var x_end = hex_origin.x + angle.cos * Hex.inner_radius
            var y_end = hex_origin.y + angle.sin * Hex.inner_radius
        
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


    static get_hex_origin_xy(q, r) {
        var x = Hex.outer_radius * (3 / 2 * q)
        var y = Hex.outer_radius * ((3).sqrt / 2 * q + (3).sqrt * r)

        return Point.new(x, y)
    }


    static key(q, r) { (q + __range) + ((r + __range) * 1000) }

    static add_relative_position(position, relative_position) { Point.new(position.q + relative_position.q, position.r + relative_position.r) }

    static get_neighbor_position(hex, direction) { add_relative_position(hex.position, direction) }
}

import "hex" for Hex
import "point" for Point
import "shove_button" for ShoveButton, MatchValue