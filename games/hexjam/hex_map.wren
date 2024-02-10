import "xs" for Input, Render, Data
import "xs_math" for Math, Vec2

class HexMap {
    static needs_visibility_update { __needs_visibility_update }
    
    static init(range) {
        // These will not change throughout game.
        __range = range
        __shove_buttons = []
        __directions = [ Point.new(1, 0), Point.new(0, 1), Point.new(-1, 1), Point.new(-1, 0), Point.new(0, -1), Point.new(1, -1) ]
        
        // Changes with each level.
        __hexes = {}
        __terrain_layout = []

        // Changes during level.
        __needs_visibility_update = false

        // debug.
        __hover_hex = []
    }


    static clearLevel() {
        __hexes.clear()
        __terrain_layout.clear()
        __move_counter = 0
        __needs_visibility_update = true
    }


    static setupLevel(player, level) {
        clearLevel()
        createTerrainLayout(level)

        // Place hexagons.
        var hexCount = 0
        for (q in -__range..__range) {

            var min_range = (-__range).max(-q - __range)
            var max_range = __range.min(-q + __range)
            
            for (r in min_range..max_range) {
                __hexes[HexMath.key(q, r)] = Hex.new(hexCount, Point.new(q, r), __terrain_layout[hexCount])

                // Set player
                if (hexCount == __start) {
                    var starting_hex = __hexes[HexMath.key(q, r)]

                    player.current_hex = starting_hex
                    player.setPosition(starting_hex.position)

                    starting_hex.occupants = [player]
                }

                // Set goal
                if (hexCount == __goal) {
                    __hexes[HexMath.key(q, r)].is_goal = true
                }

                hexCount = hexCount + 1
            }
        }

        // Starting hex in hand.
        __held_hex = []
        __held_hex.add(Hex.new(hexCount, Point.new(-4, 5), __terrain_layout[hexCount]))

        // Check each hex on outer ring to determine where to place shove buttons.
        var q = 0
        var r = (-__range)
        var next_position = Point.new(q, r)

        for (current_direction in 0..5) {
            for (count in 0...__range) {
                var hex = __hexes[HexMath.key(next_position.q, next_position.r)]

                // Store the direction of vacancies and occupancies of surrounding hexes.
                var vacancies = {}
                var occupancies = {}

                for (direction in 0..5) {
                    var neighbor_position = getNeighborPosition(hex, direction)
                    
                    if (__hexes.containsKey(HexMath.key(neighbor_position.q, neighbor_position.r))) {
                        occupancies[direction] = neighbor_position
                    } else {
                        vacancies[direction] = neighbor_position
                    }
                }

                // If the opposing sides both have a neighbor, this vacant side can be pushed.
                for (position in vacancies) {
                    var pixel_origin = getPixelPositionFromHex(hex.position.q, hex.position.r)

                    var angle_increment = (Math.pi * 2) / 6
                    var angle = (angle_increment * 0.5) + (angle_increment * position.key) 

                    var distance_from_origin = Hex.outer_radius * 1.1
                    var x = pixel_origin.x + angle.cos * distance_from_origin
                    var y = pixel_origin.y + angle.sin * distance_from_origin

                    var match_axis = -1
                    if (position.key == 0 || position.key == 3) {
                        match_axis = Axis.R
                    } else if (position.key == 1 || position.key == 4) {
                        match_axis = Axis.Q
                    } else {
                        match_axis = Axis.S
                    }
                    __shove_buttons.add(ShoveButton.new(x, y, position.key, match_axis, position.value.item(match_axis)))
                }

                // Get next hex in ring.
                next_position = getNeighborPosition(hex, current_direction)
            }
        }

        // Update visibility.
        updateVisibility(player)
    }


    static getPixelPositionFromHex(hex_position) { getPixelPositionFromHex(hex_position.q, hex_position.r) }

    static getPixelPositionFromHex(q, r) {
        var x = Hex.outer_radius * (3 / 2 * q)
        var y = Hex.outer_radius * ((3).sqrt / 2 * q + (3).sqrt * r)

        return Point.new(x, y)
    }


    static getHexPositionFromPixel(pixel_position) { getHexPositionFromPixel(pixel_position.x, pixel_position.y) }

    static getHexPositionFromPixel(x, y) {
        var unrounded_position = Point.new(
            (x * 2 / 3) / Hex.outer_radius,
            ((x * -1 / 3) + (y * (3).sqrt / 3)) / Hex.outer_radius  
        )

        return roundHexPosition(unrounded_position)
    }


    static roundHexPosition(unrounded_position) {
        var rounded_q = unrounded_position.q.round
        var rounded_r = unrounded_position.r.round
        var rounded_s = unrounded_position.s.round

        var delta_q = (unrounded_position.q - rounded_q).abs
        var delta_r = (unrounded_position.r - rounded_r).abs
        var delta_s = (unrounded_position.s - rounded_s).abs

        if (delta_q > delta_r && delta_q > delta_s) {
            rounded_q = -rounded_r - rounded_s
        } else if (delta_r > delta_s) { 
            rounded_r = -rounded_q - rounded_s
        } // S will be recaulculated by the new Point anyway.

        return Point.new(rounded_q, rounded_r)
    }


    static getHoveredHex(hex_mouse) {
       var hovered_hex_key = HexMath.key(hex_mouse.q, hex_mouse.r)

        if (__hexes.containsKey(hovered_hex_key)) {            
            return __hexes[hovered_hex_key]
        } else {
            return null
        }        
    }

    
    static displayHexInfo(hex) {
        hex.is_hovered = true
    }


    static canMoveToHex(actor, hex) {
        var isWithinMovementRange = (getDistance(hex.position, actor.current_hex.position) == 1)
        var isWalkableTerrain = (hex.terrain == Terrain.Grass || hex.terrain == Terrain.Forest)
        
        return (isWithinMovementRange && isWalkableTerrain)        
    }


    static getHoveredShoveButton(pixel_mouse) {
        var distance_button_to_edge = (ShoveButton.radius).pow(2)

        for (index in 0...__shove_buttons.count) {
            var button = __shove_buttons[index]
        
            var mouse_x_distance = button.position.x - pixel_mouse.x
            var mouse_y_distance = button.position.y - pixel_mouse.y
            var distance_from_button = (mouse_x_distance.pow(2) + mouse_y_distance.pow(2))
        
            if (distance_from_button <= distance_button_to_edge) {
                return button
            }            
        }

        return null
    }


    static update(dt, player) {
        // Get position of mouse in pixel and hex space.
        var pixel_mouse = Point.new(Input.getMouseX(), Input.getMouseY())
        var hex_mouse = getHexPositionFromPixel(pixel_mouse.x, pixel_mouse.y)


        // Display hovered hex info. Move to hex on mouse LB.
        __hover_hex.clear()
        var hex = getHoveredHex(hex_mouse)

        if (hex != null) {
            __hover_hex.add(hex)
            hex.is_hovered = true // Will display hex info.

            if (canMoveToHex(player, hex)) {
                hex.is_highlighted = true // Will signal as valid option to player.
            
                if (Input.getMouseButtonOnce(Input.mouseButtonLeft)) {
                    __move_counter = __move_counter + 1
                    __needs_visibility_update = true
            
                    return MoveToHexCommand.new(player, hex)
                }
            }
        }
        

        // Highlight hexes to be moved. Shift hexes on mouse LB.       
        var shove_button = getHoveredShoveButton(pixel_mouse)        

        // If button is hovered, highlight stack to move & move if clicked.
        if (shove_button != null) {
            shove_button.is_hovered = true

            MapActions.prepareHexLine(__hexes, shove_button.match_axis, shove_button.match_value)

            if (Input.getMouseButtonOnce(Input.mouseButtonLeft)) {
                __move_counter = __move_counter + 1
                __needs_visibility_update = true

                return ShiftHexLineCommand.new(__hexes, __held_hex, shove_button.sort_axis, shove_button.sort_ascending)
            }
        }


        // No commands to execute.
        return null
    }
    

    static lerp(a, b, t) { a + (b - a) * t }


    static hexLerp(a, b , t) {        
        return Point.new(
            lerp(a.q, b.q, t),
            lerp(a.r, b.r, t),
            lerp(a.s, b.s, t)
        )
    }


    static revealAdjacentHexes(player) {
        for (current_direction in 0...6) {
            var next_position = getNeighborPosition(player.current_hex, current_direction)
            
            var hex_key = HexMath.key(next_position.q, next_position.r)
            
            if (__hexes.containsKey(hex_key)) {
                __hexes[hex_key].is_visible = true
            }
        }
    }


    static revealHexesInLineOfSight(player) {
        // From player, draw line to every tile on outer ring.        
        var next_position = Point.new(0, -__range)

        // For each side of the map:
        for (current_direction in 0...6) {
            
            // For each hex along the side (same length as range - 1, so corners aren't doubled-up)
            for (count in 0...__range) {
                var edge_hex = __hexes[HexMath.key(next_position.q, next_position.r)]
                var distance = getDistance(player.hex_position, edge_hex.position)
                
                if (distance > 0) {

                    var pixel_origin = getPixelPositionFromHex(player.hex_position)
                    var pixel_destination = getPixelPositionFromHex(edge_hex.position)
                    
                    var origin_to_destination = Vec2.new(pixel_destination.x - pixel_origin.x, pixel_destination.y - pixel_origin.y)
                    var degree = origin_to_destination.atan2
                    
                    var step_size = origin_to_destination / distance

                    // We'll shoot 2 rays above and below the main line.                    
                    var radius_offset = Hex.inner_radius * 0.8
                    var degree_offsets = [Math.pi / 2, -Math.pi/ 2]                    

                    for (ray_index in 0...2) {
                        var ray_origin = Vec2.new(
                            pixel_origin.x + (degree + degree_offsets[ray_index]).cos * radius_offset, 
                            pixel_origin.y + (degree + degree_offsets[ray_index]).sin * radius_offset
                        )

                        // Collect all hexes between origin and destination (skipping initial start and including destination)
                        var hexes_in_line = []
                        for (n in 1..distance) {
                            var hex_position = getHexPositionFromPixel(ray_origin + (step_size * n))
                            hexes_in_line.add(__hexes[HexMath.key(hex_position.q, hex_position.r)])
                        }

                        // Check visibility of each hex.
                        var has_line_of_sight = true
                        for (n in 0...hexes_in_line.count) {
                            var hex = hexes_in_line[n]

                            // A hex is visible if at least 1 ray can see it.
                            if (has_line_of_sight) {
                                hex.is_visible = true
                            }

                            // Mountains and forests block line of sight.
                            if (hex.terrain == Terrain.Mountain || hex.terrain == Terrain.Forest) {
                                has_line_of_sight = false
                            }
                        }
                    }
                }

                // Get next hex on outer ring.
                next_position = getNeighborPosition(edge_hex, current_direction)
            }
        }
    }


    static updateVisibility(player) {
        // Mark all tiles as not visible.
        for (hex in __hexes) {
            hex.value.is_visible = false
        }

        // Reveal map based on player location.
        if (player.current_hex.id == __held_hex[0].id) {
            // Leave everything else hidden.
        } else if (player.current_hex.terrain == Terrain.Forest) {
            revealAdjacentHexes(player)        
        } else {
            revealHexesInLineOfSight(player)
        }

        // Player can always see the held hex.
        __held_hex[0].is_visible = true

        // Player can always see the hex they are on.
        if (player.current_hex.id != __held_hex[0].id) {            
            __hexes[HexMath.key(player.hex_position.q, player.hex_position.r)].is_visible = true
        }

         // Reset visiblity flag. 
        __needs_visibility_update = false
    }



    static render(origin) {
        for (hex in __hexes) {
            draw_hex(hex.value)
            hex.value.reset()
        }

        draw_hex(__held_hex[0])

        for (button in __shove_buttons) {
            draw_button(button)
            button.is_hovered = false
        }

        // Turn tracker
        var x = Data.getNumber("Width") / 2
        var y = Data.getNumber("Height") / 2
        var x_offset = 180
        var y_offset = 40
        Render.setColor(0xFFFFFFFF)

        if (__best_move == -1) {
            Render.shapeText("Aim: ???", x - x_offset, -y + (y_offset * 2), 3)
        } else {
            Render.shapeText("Aim: %(__best_move)", x - x_offset, -y + (y_offset * 2), 3)
        }

        Render.setColor(0xFFFF00FF)
        Render.shapeText("Moves: %(__move_counter)", x - x_offset, -y + y_offset, 3)

        if (__hover_hex.count > 0) {
            // Hex info.
            Render.setColor(0xFFFFFFFF)
            Render.shapeText("#%(__hover_hex[0].id) @ (%(__hover_hex[0].position.q), %(__hover_hex[0].position.r), %(__hover_hex[0].position.s))", x - x_offset, y - y_offset, 2)
            var x = Data.getNumber("Width") / 2
            var y = Data.getNumber("Height") / 2
            var x_offset = 230
            var y_offset = 10

            // Debug visibility.
            if (Data.getBool("Debug")) {
                var edge_hex = __hover_hex[0]
                var distance = getDistance(origin, edge_hex.position)
                
                if (distance > 1) {
                    var pixel_origin = getPixelPositionFromHex(origin)
                    var pixel_edge_hex = getPixelPositionFromHex(edge_hex.position)
                    
                    var origin_to_hex = Vec2.new(pixel_edge_hex.x - pixel_origin.x, pixel_edge_hex.y - pixel_origin.y)
                    var degree = origin_to_hex.atan2
                    
                    var step_size = origin_to_hex / distance

                    // We'll shoot 2 "rays" above and below the main line.
                    var circle_sizes = [6, 10]
                    var colors = [0x00FFFFFF, 0xFFFF00FF]

                    var radius_offset = Hex.inner_radius * 0.8
                    var degree_offsets = [Math.pi / 2, -Math.pi/ 2]                    

                    for (ray_index in 0...2) {
                        var ray_origin = Vec2.new(
                            pixel_origin.x + (degree + degree_offsets[ray_index]).cos * radius_offset, 
                            pixel_origin.y + (degree + degree_offsets[ray_index]).sin * radius_offset
                        )

                        for (n in 1..distance) {
                            var position_xy = ray_origin + (step_size * n)

                            Render.setColor(colors[ray_index])
                            Render.circle(position_xy.x, position_xy.y, circle_sizes[ray_index], 8)                        
                        }
                    }
                }
            }
        }
    }


    static draw_hex(hex) {
        var origin = getPixelPositionFromHex(hex.position.q, hex.position.r)

        var angle_increment = (Math.pi * 2) / 6
        var angle = angle_increment

        var x_start = origin.x + angle.cos * Hex.inner_radius
        var y_start = origin.y + angle.sin * Hex.inner_radius

        // Border color.
        if (hex.id == __held_hex[0].id) {
            Render.setColor(0xFFFFFFFF)
        } else if (hex.is_highlighted) {
            Render.setColor(0x00FF00FF)
        } else if (hex.is_in_stack) {
            Render.setColor(0xFFFF00FF)
        } else if (hex.is_visible) {
            Render.setColor(0xFF00FFFF)
        } else {
            Render.setColor(0x2A2A2AFF)
        }

        for (sides in 1..6) {
            angle = angle + angle_increment

            var x_end = origin.x + angle.cos * Hex.inner_radius
            var y_end = origin.y + angle.sin * Hex.inner_radius
        
            Render.begin(Render.lines)
            Render.vertex(x_start, y_start)
            Render.vertex(x_end, y_end)
            Render.end()

            x_start = x_end
            y_start = y_end   
        }
        
        // Goal image.
        if (hex.is_goal) {
            Render.setColor(0xFFFF00FF)
            Render.circle(origin.x, origin.y, 6, 8)
            Render.circle(origin.x, origin.y, 10, 16)
        }

        // Terrain features.
        if (hex.is_visible) {
            if (hex.terrain == Terrain.Grass) {
                Render.setColor(0x00FF00FF)
                for (patch_count in 0..0) {
                    var base = Point.new(origin.x - 12, origin.y + (patch_count == 0 ? -25 : 20))
                    for (blade_count in 0..4) {
                        Render.begin(Render.lines)
                        Render.vertex(base.x + (blade_count * 6), base.y)
                        Render.vertex(base.x + (blade_count * 6), base.y + 6)
                        Render.end()
                    }
                }
            } else if (hex.terrain == Terrain.Water) {
                Render.setColor(0x00FFFFFF)
                Render.circle(origin.x, origin.y, Hex.inner_radius * 0.7, 16)
            } else if (hex.terrain == Terrain.Mountain) {
                Render.setColor(0xFF5522FF)
                Render.begin(Render.lines)
                Render.vertex(origin.x - 20, origin.y - 20)
                Render.vertex(origin.x, origin.y + 25)
                Render.vertex(origin.x + 20, origin.y - 20)
                Render.end()
            } else if (hex.terrain == Terrain.Forest) {
                Render.setColor(0x00AA00FF)
                for (tree_count in 0..1) {
                    var x_offset = tree_count == 0 ? -20 : 20
                    for (branch_count in 0..1) {
                        var y_offset = branch_count * -12
                        Render.begin(Render.lines)
                        Render.vertex(x_offset + origin.x - 10, y_offset + origin.y)
                        Render.vertex(x_offset + origin.x, y_offset + origin.y + 20)
                        Render.vertex(x_offset + origin.x + 10, y_offset + origin.y)
                        Render.end()
                    }
                }
            }
        }
    }


    static draw_button(button) {
        if (button.is_hovered) {
            Render.setColor(0x00FF00FF)
        } else {
            Render.setColor(0xFFFFFFFF)
        }
        Render.circle(button.position.x, button.position.y, ShoveButton.radius, 16)
    }

    static addRelativePosition(position, relative_position) { Point.new(position.q + relative_position.q, position.r + relative_position.r) }

    static getNeighborPosition(hex, direction) { addRelativePosition(hex.position, __directions[direction]) }

    static getDistance(a, b) { ((a.q - b.q).abs + (a.q + a.r - b.q - b.r).abs + (a.r - b.r).abs) / 2 }

    static createTerrainLayout(level) {
        if (level == 1) {
            __best_move = 4
            createLevel1Terrain()
            __start = 18
            __goal = 21
        } else if (level == 2) {
            __best_move = 3
            createLevel2Terrain()
            __start = 15
            __goal = 21
        } else if (level == 3) {
            __best_move = -1
            createLevel3Terrain()
        }
    }

    static createLevel1Terrain() {
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)

        __terrain_layout.add(Terrain.Forest)
        __terrain_layout.add(Terrain.Forest)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Forest)
        __terrain_layout.add(Terrain.Forest)

        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)

        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)

        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)

        __terrain_layout.add(Terrain.Forest)
        __terrain_layout.add(Terrain.Forest)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Forest)
        __terrain_layout.add(Terrain.Forest)

        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)
        __terrain_layout.add(Terrain.Grass)

        __terrain_layout.add(Terrain.Mountain)
    }

    static createLevel2Terrain() {
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)

        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Mountain)

        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)

        __terrain_layout.add(Terrain.Forest)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Grass)

        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Mountain)

        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Water)

        __terrain_layout.add(Terrain.Mountain)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Water)
        __terrain_layout.add(Terrain.Water)

        __terrain_layout.add(Terrain.Water)        
    }

     static createLevel3Terrain() {
        var random = Random.new()
        
        for (hex in 0...38) {
            var terrain = random.int(0, 4)

            if (terrain == 0) {
                __terrain_layout.add(Terrain.Water)
            } else if (terrain == 1) {
                __terrain_layout.add(Terrain.Mountain)
            } else if (terrain == 2) {
                __terrain_layout.add(Terrain.Forest)
            } else {
                __terrain_layout.add(Terrain.Grass)
            }
        }

        // Start and goal spaces.
        __start = random.int(4, 15)
        __goal = random.int(22, 33)

        __terrain_layout[__start] = Terrain.Forest
        __terrain_layout[__goal] = Terrain.Grass

     }
}

import "hex" for Hex, Terrain
import "point" for Point, Axis
import "shove_button" for ShoveButton
import "player" for Player
import "random" for Random
import "map_actions" for MapActions
import "hex_math" for HexMath
import "commands" for MoveToHexCommand, ShiftHexLineCommand