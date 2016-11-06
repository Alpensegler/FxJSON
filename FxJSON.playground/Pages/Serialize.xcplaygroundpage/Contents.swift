import FxJSON

enum Form: String {
  case JSONMappable
  case JSONDecodable
  case JEONEncodable
  case JSONCodable
}

enum Type: String {
  case `struct`
  case `class`
}

extension String {
  
  func firstUppercased() -> String {
    let first = substring(to: index(after: startIndex)).uppercased()
    let other = substring(from: index(after: startIndex))
    return first + other
  }
}

//let data = try Data(contentsOf: #fileLiteral(resourceName: "JSON.json"))
//let object = try JSONSerialization.jsonObject(with: data)
//if let dict = object as? [String: Any] {
//  CFGetTypeID(dict["code"]!)
//}

//extension JSON {
//  
//  func serializeTo(_ type: Type, _ name: String, with form: Form, using space: String) {
//    var jsonStack = [(JSON, String)]()
//    print("\n\(type.rawValue) \(name): \(form.rawValue) {")
//    switch self {
//    case .object:
//      for (key, json) in asDict {
//        switch json {
//        case .object, .array:
//          print("\(space)\(key): \(key.firstUppercased())")
//          jsonStack.append((json, key))
//          defer { json.serializeTo(type, name.firstUppercased(), with: form, using: space) }
//        case .string:
//          print("\(space)\(key): String")
//        case .bool:
//          print("\(space)\(key): Bool")
//        case .number(let number):
//          print("\(space)\(key): Int")
//        case .error(let error):
//          fatalError("\(error)")
//        case .null:
//          print("\(space)\(key): <#T##Unknow#>")
//        }
//      }
//    case .array:
//      first?.serializeTo(type, name, with: form, using: space)
//    default: fatalError()
//    }
//    print("}")
//    for (json, name) in jsonStack {
//      json.serializeTo(type, name.firstUppercased(), with: form, using: space)
//    }
//  }
//}



//JSON(jsonData: try? Data(contentsOf: #fileLiteral(resourceName: "JSON.json"))).serializeTo(.struct, "user", with: .JSONDecodable, using: "  ")
