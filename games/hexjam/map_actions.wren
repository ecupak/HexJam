
class MapActions {
    
/*
    HexLine actions
    prepareHexLine: Highlight line of hexes that will be moved on confirmation.
    shiftHexLine: Moves line of hexes - adds held hex to start of line, moves all hexes 1 hex down the line, and removes last hex and sets it as held hex.
*/
    static prepareHexLine(hexes, match_axis, match_value) {
        var hexes_to_move = []
        
        for (hex in hexes) {
            if (hex.value.position.item(match_axis) == match_value) {
                hexes_to_move.add(hex.value)
                hex.value.is_in_stack = true
                
                // TODO: add check to see if hex is immobile. If so, add position of offending tile to passed in list of offending tiles.
                // Render line as bad color, highlight offending tiles in worse color.
                // If no offending tiles, then list will be empty and that is how the other methods will know what to do.
            }
        }
    }


    static shiftHexLine(hexes, held_hex, sort_axis, sort_ascending) {
        // Gather hexes to be moved.
        var hexes_to_move = []

        for (hex in hexes) {      
            if (hex.value.is_in_stack) {
                hexes_to_move.add(hex.value)                
            }
        }

        // Bubble sort them based on the axis to be moved.        
        for (iteration in 0...(hexes_to_move.count - 1)) {
            var swapped = false

            for (index in 0...(hexes_to_move.count - 1 - iteration)) {
                var should_swap = false

                if (sort_ascending) {
                    should_swap = hexes_to_move[index].position.item(sort_axis) > hexes_to_move[index + 1].position.item(sort_axis)
                } else { // descending order
                    should_swap = hexes_to_move[index].position.item(sort_axis) < hexes_to_move[index + 1].position.item(sort_axis)
                }

                if (should_swap) {
                    var temp = hexes_to_move[index]
                    hexes_to_move[index] = hexes_to_move[index + 1]
                    hexes_to_move[index + 1] = temp

                    swapped = true
                }    
            }

            // Early out. If nothing moved during the iteration, everything is sorted.
            if (swapped == false) {
                break
            }
        }

        // Reassign hex positions.

        // ... Held hex is inserted at the start of the line.
        // (Store the held hex position so it is not lost after reassignment.)
        var held_hex_position = held_hex[0].position
        var previous_held_hex = held_hex[0]
        held_hex.clear()
        
        previous_held_hex.position = hexes_to_move[0].position
        hexes[HexMath.key(previous_held_hex.position.q, previous_held_hex.position.r)] = previous_held_hex

        // ... Hexes in the line are assigned the position of the next hex.
        // (Skip last hex since it is assigned differently - as the new held hex.)
        for (index in 0...(hexes_to_move.count - 1)) {
            var hex_to_move = hexes_to_move[index]
            hex_to_move.position = hexes_to_move[index + 1].position
            
            hexes[HexMath.key(hex_to_move.position.q, hex_to_move.position.r)] = hex_to_move
        }        

        // ... Assign the last hex in line as the new held hex.
        held_hex.add(hexes_to_move[hexes_to_move.count - 1])
        held_hex[0].position = held_hex_position

        System.print("New held hex id: %(held_hex[0].id)")

        // Clear marked hexes.
        for (hex in hexes) {            
            hex.value.is_in_stack = false
        }
    }


/*

*/
    static moveToHex(actor, target_hex) {
        actor.current_hex = target_hex
    }
}

import "hex_math" for HexMath