import Foundation
import FxJSON

var str = "Hello, playground"

var json = JSON()

json.string = "string"
json.int = 123
json.double = 123.123

debugPrint(wrap(json))

let dict = ["aaa":123, "bbb":123]

dict.json

struct SOme: Codable {
    let string: String
    let aa: Int
    let bb: Double
}

@_silgen_name("swift_getFieldAt")
func _getFieldAt(
    _ type: Any.Type,
    _ index: Int,
    _ callback: @convention(c) (UnsafePointer<CChar>, UnsafeRawPointer, UnsafeRawPointer) -> Void,
    _ ctx: UnsafeRawPointer
)

final class User: NSObject {
    var name: String = ""
    var age: Int = 0
}

var test = "hello"

_getFieldAt(User.self, 0, { name, type, ctx in
    let name = String(cString: name)
    let type = unsafeBitCast(type, to: Any.Type.self)
    print("\(name): \(type)")
    print(ctx.assumingMemoryBound(to: String.self).pointee)
}, &test) // prints: age: Int, hello

