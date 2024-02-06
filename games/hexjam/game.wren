import "xs" for Data, Input, Audio    // These are the parts of the xs we will be using


// The entry point (main) is the Game class
class Game {
    // Config gets called before the engine is initialized
    static config() {
        // Configure the window in xs
        Data.setNumber("Width", 720, Data.system)
        Data.setNumber("Height", 480, Data.system)
        Data.setNumber("Multiplier", 1, Data.system)
    }

    
    // You can initialize you game specific data here.
    static init() {     
        System.print("Hello HexJam")
        
        var outer_radius = 50
        var range = 2

        Hex.init_as_flat_top(outer_radius)
        HexMap.init(range)

        __level = 1
        setupLevel()
    }
                        
    
    // The update method is called once per tick, gameplay code goes here.
    static update(dt) {
        HexMap.update(dt)
    }
    
    
    // The render method is called once per tick, right after update.
    static render() {
        HexMap.render()
    }


    static setupLevel() {
        HexMap.setupLevel()
    }

    static unkey(value) {
        var r = value / 1000
        value = value - r
        var q = value
        
        return Point.new(q, r)
    }
}

import "hex_map" for HexMap
import "hex" for Hex, Point