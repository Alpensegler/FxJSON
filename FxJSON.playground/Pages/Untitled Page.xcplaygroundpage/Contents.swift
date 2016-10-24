import FxJSON
import Foundation

let i = 0 as Any

//let some = type(of: i)

let any = [:] as Any

if let any = any as? [String: Any] {
    print(true)
}

String(json: 0)

let json = JSON(123456)

let some = ["aaaa": ["aaaaa": 123]]

for a in some.keys