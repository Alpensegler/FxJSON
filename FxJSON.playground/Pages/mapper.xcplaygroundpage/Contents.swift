import FxJSON

public extension JSON {
    
    class Mapper {
        var json = JSON()
        
        subscript(some: String) -> Mapper {
            get {
                return self
            }
            set {
                print(true)
            }
        }
    }
}

func map(map: inout JSON.Mapper) {
    map = JSON.Mapper()
}

var map = JSON.Mapper()

map(map: &map["a"])
