class Axis {
    static X { 0 }
    static Y { 1 }
    static Z { 2 }

    static Q { 0 }
    static R { 1 }
    static S { 2 }
}

class Point {
    x { _points[0] } 
    x=(value) { 
       _points[0] = value
    }

    y { _points[1] } 
    y=(value) { 
       _points[1] = value
    }
    
    z { _points[2] } 
    z=(value) { 
       _points[2] = value
    }

    q { _points[0] } 
    q=(value) { 
       _points[0] = value
    }
    
    r { _points[1] } 
    r=(value) { 
       _points[1] = value
    }

    s { _points[2] } 
    s=(value) { 
       _points[2] = value
    }

    item(index) { _points[index ]}

    construct new(first, second) {
        _points = [first, second, -first - second]
    }

    construct new(first, second, third) {
      _points = [first, second, third]
    }
}