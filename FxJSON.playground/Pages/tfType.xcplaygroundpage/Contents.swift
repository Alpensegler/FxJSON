import FxJSON

let json = JSON {
    $0["name"] << "Frain"
//    $0["sub"] << JSON {
        $0["age"] << 20
        $0["tall"] << 170.0
//    }
}

class A: JSONMappable {
    
    let name = ""
    let age = 0
    let tall = 0.0
    
    required init() {}
}

let a = A(json)

dump(a)

print(a.json)