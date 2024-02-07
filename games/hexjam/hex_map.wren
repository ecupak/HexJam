import "xs" for Input, Render
import "xs_math" for Math

class HexMap {
    range{ __range }

    static init(range) {
        __range = range
        __hexes = {}
        __hexes_to_move = []
        __shove_buttons = []
        __directions = [ Point.new(1, 0), Point.new(0, 1), Point.new(-1, 1), Point.new(-1, 0), Point.new(0, -1), Point.new(1, -1) ]
        __terrain_layout = []
    }


    static clearLevel() {
        __hexes.clear()
        __terrain_layout.clear()
        __move_counter = 0
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
                __hexes[key(q, r)] = Hex.new(hexCount, Point.new(q, r), __terrain_layout[hexCount])

                // Set player
                if (hexCount == __start) {
                    player.current_hex = __hexes[key(q, r)]
                }

                // Set goal
                if (hexCount == __goal) {
                    __hexes[key(q, r)].is_goal = true
                }

                hexCount = hexCount + 1
            }
        }

        // Starting hex in hand.
        __held_hex = Hex.new(hexCount, Point.new(-4, 5), __terrain_layout[hexCount])

        // Check each hex on outer ring to determine where to place shove buttons.
        var q = 0
        var r = (-__range)
        var next_position = Point.new(q, r)

        for (current_direction in 0..5) {
            for (count in 0...__range) {
                var hex = __hexes[key(next_position.q, next_position.r)]

                // Store the direction of vacancies and occupancies of surrounding hexes.
                var vacancies = {}
                var occupancies = {}

                for (direction in 0..5) {
                    var neighbor_position = this.get_neighbor_position(hex, direction)
                    
                    if (__hexes.containsKey(key(neighbor_position.q, neighbor_position.r))) {
                        occupancies[direction] = neighbor_position
                    } else {
                        vacancies[direction] = neighbor_position
                    }
                }

                // If the opposing sides both have a neighbor, this vacant side can be pushed.
                for (position in vacancies) {
                    var hex_origin = this.get_hex_origin_xy(hex.position.q, hex.position.r)

                    var angle_increment = (Math.pi * 2) / 6
                    var angle = (angle_increment * 0.5) + (angle_increment * position.key) 

                    var distance_from_origin = Hex.outer_radius * 1.1
                    var x = hex_origin.x + angle.cos * distance_from_origin
                    var y = hex_origin.y + angle.sin * distance_from_origin

                    if (position.key == 0 || position.key == 3) {
                        __shove_buttons.add(ShoveButton.new(x, y, position.key, MatchType.R, position.value.r))
                    } else if (position.key == 1 || position.key == 4) {
                        __shove_buttons.add(ShoveButton.new(x, y, position.key, MatchType.Q, position.value.q))
                    } else {
                        __shove_buttons.add(ShoveButton.new(x, y, position.key, MatchType.S, (-position.value.q) - position.value.r))
                    }
                }

                // Get next hex in ring.
                next_position = get_neighbor_position(hex, current_direction)
            }
        }
    }


    static update(dt, player) {
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

        // Highlight hex under mouse if it is valid movement hex (within 1 space and grass/forest terrain).
        var hovered_hex = key(rounded_q, rounded_r)
        if (__hexes.containsKey(hovered_hex) && this.get_distance(__hexes[hovered_hex].position, player.current_hex.position) == 1) {
            if (__hexes[hovered_hex].terrain == Terrain.Grass || __hexes[hovered_hex].terrain == Terrain.Forest) {
                __hexes[hovered_hex].is_hovered = true
                
                if (Input.getMouseButtonOnce(Input.mouseButtonLeft)) {
                    player.current_hex = __hexes[hovered_hex]
                    __move_counter = __move_counter + 1
                }
            }        
        }

        // Check against buttons.
        var hovered_button_index = -1
        var distance_button_to_edge = (ShoveButton.radius).pow(2)
        for (index in 0...__shove_buttons.count) {
            var button = __shove_buttons[index]
        
            var mouse_x_distance = button.position.x - x
            var mouse_y_distance = button.position.y - y
            var distance_from_button = (mouse_x_distance.pow(2) + mouse_y_distance.pow(2))
        
            if (distance_from_button <= distance_button_to_edge) {
                button.is_hovered = true
                hovered_button_index = index
                break
            }
        }

        // If button is hovered, highlight stack to move if clicked.
        __hexes_to_move.clear()
        if (hovered_button_index > -1) {
            var button = __shove_buttons[hovered_button_index]

            for (hex in __hexes) {
                if (button.match_type == MatchType.Q && button.match_value == hex.value.position.q) {
                    __hexes_to_move.add(hex.value)
                } else if (button.match_type == MatchType.R && button.match_value == hex.value.position.r) {
                    __hexes_to_move.add(hex.value)
                } else if (button.match_type == MatchType.S && button.match_value == hex.value.position.s) {
                    __hexes_to_move.add(hex.value)
                }
            }
        }

        if (__hexes_to_move.count > 0) {
            
            // Mark all hexes in stack.
            for (hex in __hexes_to_move) {
                hex.is_in_stack = true
            }

            // If mouse clicked and stack has hexes, move them.
            if (Input.getMouseButtonOnce(Input.mouseButtonLeft)) {
                __move_counter = __move_counter + 1

                // Sort the hexes by match type and direction
                var button = __shove_buttons[hovered_button_index]

                for (passes in 0...(__hexes_to_move.count - 1)) {
                    var swap = false
                    var swap_index = 0

                    for (index in 0...(__hexes_to_move.count - 1 - passes)) {
                        var should_swap = false

                        if (button.is_ascending) {
                            if (button.sort_type == MatchType.Q) {
                                if (__hexes_to_move[index].position.q > __hexes_to_move[index + 1].position.q) {
                                    should_swap = true
                                }
                            } else if (button.sort_type == MatchType.R) {
                                if (__hexes_to_move[index].position.r > __hexes_to_move[index + 1].position.r) {
                                    should_swap = true
                                }
                            }
                        } else { // descending order
                            if (button.sort_type == MatchType.Q) {
                                if (__hexes_to_move[index].position.q < __hexes_to_move[index + 1].position.q) {
                                    should_swap = true
                                }
                            } else if (button.sort_type == MatchType.R) {
                                if (__hexes_to_move[index].position.r < __hexes_to_move[index + 1].position.r) {
                                    should_swap = true
                                }
                            }
                        }

                        // Swap
                        if (should_swap) {
                            var temp = __hexes_to_move[index]
                            __hexes_to_move[index] = __hexes_to_move[index + 1]
                            __hexes_to_move[index + 1] = temp

                            swap = true
                        }    
                    } // single pass

                    if (swap == false) {
                        break
                    }
                } // sorting

                // Move hexes to new positions.
                var held_position = __held_hex.position
                __held_hex.position = __hexes_to_move[0].position
                for (index in 0...__hexes_to_move.count - 1) {
                    __hexes_to_move[index].position = __hexes_to_move[index + 1].position
                    __hexes_to_move[index].is_in_stack = false
                }
                __hexes_to_move[__hexes_to_move.count - 1].position = held_position
                __hexes_to_move[__hexes_to_move.count - 1].is_in_stack = false

                // Reassign hexes in map. Skip the last one (now the held hex). Manually add the previous held hex.
                for (index in 0...__hexes_to_move.count - 1) {
                    var hex = __hexes_to_move[index]
                    __hexes[key(hex.position.q, hex.position.r)] = hex
                }
                __hexes[key(__held_hex.position.q, __held_hex.position.r)] = __held_hex
                __held_hex = __hexes_to_move[__hexes_to_move.count - 1]

            } // Mouse click
        } // Hex stack has items
    }
    
    static render() {
        for (hex in __hexes) {
            draw_hex(hex.value)
            hex.value.is_hovered = false
            hex.value.is_in_stack = false
        }

        draw_hex(__held_hex)

        for (button in __shove_buttons) {
            draw_button(button)
            button.is_hovered = false
        }

        // Turn tracker
        Render.setColor(0xFFFFFFFF)
        if (__best_move == -1) {
            Render.shapeText("Aim: ???", 180, -290, 3)
        } else {
            Render.shapeText("Aim: %(__best_move)", 180, -290, 3)
        }

        Render.setColor(0xFFFF00FF)
        Render.shapeText("Moves: %(__move_counter)", 180, -330, 3)
    }


    static draw_hex(hex) {
        var origin = this.get_hex_origin_xy(hex.position.q, hex.position.r)

        var angle_increment = (Math.pi * 2) / 6
        var angle = angle_increment

        var x_start = origin.x + angle.cos * Hex.inner_radius
        var y_start = origin.y + angle.sin * Hex.inner_radius

        // Border color.
        if (hex.id == __held_hex.id) {
            Render.setColor(0xFFFFFFFF)
        } else if (hex.is_hovered) {
            Render.setColor(0x00FF00FF)
        } else if (hex.is_in_stack) {
            Render.setColor(0xFFFF00FF)
        } else {
            Render.setColor(0xFF00FFFF)
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
        // Render.setColor(0xFFFFFFFF)
        // Render.shapeText("%(hex.id)", origin.x, origin.y, 2)
    }


    static get_hex_origin_xy(q, r) {
        var x = Hex.outer_radius * (3 / 2 * q)
        var y = Hex.outer_radius * ((3).sqrt / 2 * q + (3).sqrt * r)

        return Point.new(x, y)
    }


    static draw_button(button) {
        if (button.is_hovered) {
            Render.setColor(0x00FF00FF)
        } else {
            Render.setColor(0xFFFFFFFF)
        }
        Render.circle(button.position.x, button.position.y, ShoveButton.radius, 16)
    }

    static key(q, r) { (q + __range) + ((r + __range) * 1000) }

    static add_relative_position(position, relative_position) { Point.new(position.q + relative_position.q, position.r + relative_position.r) }

    static get_neighbor_position(hex, direction) { add_relative_position(hex.position, __directions[direction]) }

    static get_distance(a, b) { ((a.q - b.q).abs + (a.q + a.r - b.q - b.r).abs + (a.r - b.r).abs) / 2 }

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
import "point" for Point
import "shove_button" for ShoveButton, MatchType
import "player" for Player
import "random" for Random