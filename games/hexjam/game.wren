import "xs" for Data, Render, Input, Audio    // These are the parts of the xs we will be using


class GS {
    static Play { 0 }
    static Win { 1 }
}

// The entry point (main) is the Game class
class Game {
    // Config gets called before the engine is initialized
    static config() {
        // Configure the window in xs
        Data.setNumber("Width", 720, Data.system)
        Data.setNumber("Height", 740, Data.system)
        Data.setNumber("Multiplier", 1, Data.system)
    }

    
    // You can initialize you game specific data here.
    static init() {     
        // Initialize static variables.
        var outer_radius = 50
        Hex.init(outer_radius)

        var range = 3
        HexMath.init(range)
        HexMap.init(range)

        // Create player.
        __player = Player.new(Point.new(0, 0))

        // Setup starting level.
        __max_level = 3
        __level = 1
        setupLevel()

        // Play game.
        __state = GS.Play
    }
                        
    
    // The update method is called once per tick, gameplay code goes here.
    static update(dt) {
        if (__state == GS.Play) {
            var command = HexMap.update(dt, __player)
            
            if (command != null) {
                command.execute()
            }

            if (__player.current_hex.is_goal) {
                __state = GS.Win
            }

            __player.update(dt)
        } else if (__state == GS.Win) {
            if (Input.getMouseButtonOnce(Input.mouseButtonLeft)) {
                __state = GS.Play
                __level = __level == __max_level ? 1 : __level + 1
                System.print(__level)
                setupLevel()
            }
        }
    }
    
    
    // The render method is called once per tick, right after update.
    static render() {
        HexMap.render()
        __player.render()

        var x = 20 + (Data.getNumber("Width") / -2)
        var y = (Data.getNumber("Height") / 2)
        Render.setColor(0x0000FFFF)
        if (__level == __max_level) {
            Render.shapeText("Level %(__level) (randomized!)", x, -y + 40, 3)
        } else {
            Render.shapeText("Level %(__level)", x, -y + 40, 3)
        }

        if (__state == GS.Win){
            Render.setColor(0x00AA00FF)
            Render.shapeText("WIN", x, y - 10, 5)

            if (__level < __max_level) {
                Render.setColor(0xAA5500FF)
                Render.shapeText("Click to continue", x + 100, y - 10, 3)
            } else {
                Render.setColor(0xAA5500FF)
                Render.shapeText("Click to play again", x + 100, y - 10, 3)
            }
        }
    }


    static setupLevel() {
        HexMap.setupLevel(__player, __level)
    }
}

import "hex_map" for HexMap
import "hex" for Hex, Point
import "shove_button" for ShoveButton
import "player" for Player
import "hex_math" for HexMath