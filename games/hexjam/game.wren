import "xs" for Data, Input, Audio    // These are the parts of the xs we will be using
//import "xs_math" for Math
import "hex_map" for HexMap
import "hex" for Hex, Point


// The entry point (main) is the Game class
class Game {
    // Config gets called before the engine is initialized
    static config() {
        // Configure the window in xs
        Data.setNumber("Width", 640, Data.system)
        Data.setNumber("Height", 360, Data.system)
        Data.setNumber("Multiplier", 1, Data.system)
    }

    
    // You can initialize you game specific data here.
    static init() {     
        System.print("Hello myGame")   
        
        HexMap.init_as_flat_top(30, 2)

        var range = HexMap.range
        
        __hexes = {}
        var hexCount = 0
        for (q in -range..range) {  
            var min_range = (-range).max(-q - range)
            var max_range = range.min(-q + range)
            for (r in min_range..max_range) {                
                __hexes[key(q, r)] = Hex.new(hexCount, Point.new(q, r))
                hexCount = hexCount + 1
            }
        }
    }    
                        
    
    // The update method is called once per tick, gameplay code goes here.
    static update(dt) {
        var x = Input.getMouseX()
        var y = Input.getMouseY()

        var initial_q = (x * 2 / 3) / 30 // size of hex (radius)
        var initial_r = ((x * -1 / 3) + (y * (3).sqrt / 3)) / 30
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

        //System.print("%(rounded_q), %(rounded_r)")

        var key = key(rounded_q, rounded_r)
        if (__hexes.containsKey(key)) {
            __hexes[key].is_hovered = true
        }
    }
    
    
    // The render method is called once per tick, right after update.
    static render() {
        for (hex in __hexes) {
            HexMap.draw_hex(hex.value)
            hex.value.is_hovered = false
        }
    }


    static key(q, r) { (q + HexMap.range) + ((r + HexMap.range) * 1000) }
    
    static unkey(value) {
        var r = value / 1000
        value = value - r
        var q = value
        
        return Point.new(q, r)
    }
}