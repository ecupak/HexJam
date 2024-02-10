class Command {
    execute() {
        System.print("Empty command.")
    }
}


class MoveToHexCommand is Command{
    construct new(actor, target_hex) {
        _actor = actor
        _target_hex = target_hex
    }

    execute() {
        _actor.current_hex.occupants.clear()

        _actor.current_hex = _target_hex
        _actor.setPosition(_target_hex.position)

        _target_hex.occupants = [_actor]
    }
}


class ShiftHexLineCommand is Command{
    construct new(hexes, held_hex, sort_axis, sort_ascending) {
        _hexes = hexes
        _held_hex = held_hex
        _sort_axis = sort_axis
        _sort_ascending = sort_ascending
    }

    execute() {
        // Gather hexes to be moved.
        var hexes_to_move = []

        for (hex in _hexes) {      
            if (hex.value.is_in_stack) {
                hexes_to_move.add(hex.value)                
            }
        }

        // Bubble sort them based on the axis to be moved.        
        for (iteration in 0...(hexes_to_move.count - 1)) {
            var swapped = false

            for (index in 0...(hexes_to_move.count - 1 - iteration)) {
                var should_swap = false

                if (_sort_ascending) {
                    should_swap = hexes_to_move[index].position.item(_sort_axis) > hexes_to_move[index + 1].position.item(_sort_axis)
                } else { // descending order
                    should_swap = hexes_to_move[index].position.item(_sort_axis) < hexes_to_move[index + 1].position.item(_sort_axis)
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
        var held_hex_position = _held_hex[0].position
        var previous_held_hex = _held_hex[0]
        _held_hex.clear()
        
        previous_held_hex.position = hexes_to_move[0].position
        previous_held_hex.moved()
        _hexes[HexMath.key(previous_held_hex.position.q, previous_held_hex.position.r)] = previous_held_hex

        // ... Hexes in the line are assigned the position of the next hex.
        // (Skip last hex since it is assigned differently - as the new held hex.)
        for (index in 0...(hexes_to_move.count - 1)) {
            var hex_to_move = hexes_to_move[index]
            hex_to_move.position = hexes_to_move[index + 1].position
            hex_to_move.moved()            
            _hexes[HexMath.key(hex_to_move.position.q, hex_to_move.position.r)] = hex_to_move
        }        

        // ... Assign the last hex in line as the new held hex.
        _held_hex.add(hexes_to_move[hexes_to_move.count - 1])
        _held_hex[0].position = held_hex_position
        _held_hex[0].moved() 

        // Clear marked hexes.
        for (hex in _hexes) {            
            hex.value.is_in_stack = false
        }
    }
}


import "hex_math" for HexMath
import "hex_map" for HexMap