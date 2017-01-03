/*:
 > # To use **FxJSON.playground**:
 1. Open **FxJSON.xcworkspace**.
 1. Build the **FxJSON** scheme using iPhone 5s simulator (**Product** → **Build**).
 1. Open **FxJSON** playground in the **Project navigator**.
 1. You can see JSON data in playground **FxJSON** → **Resources** → **json.json**

 ### Other Contents:
 - [Deal with JSON](Deal%20with%20JSON)
 - [Using Protocols](Using%20Protocols)
 ----
 */
import FxJSON

//: Assume that you have a json data:

let jsonData = try Data(contentsOf: #fileLiteral(resourceName: "JSON.json"))
let jsonString = String(data: jsonData, encoding: .utf8)

//: You only need to adopt `JSONMappable` and implement init()
struct User: JSONCodable {
  let id: Int64
  let name: String
  let admin: Bool
  let website: URL?       //URL is supported
  let lastLogin: Date     //Date is supported through DateTransform.default
  let friends: [User]     //Also your own type
}
//: Or specify the way transforming (optional)
let webTransform = CustomTransform<String, String>.fromJSON { "https://\($0)" }
let dateTransform = DateTransform.timeIntervalSince(.year1970) //or you can set DateTransform.default

extension User {
  static func specificOptions() -> [String: SpecificOption] {
    return [
      "id": "userID",
      "website": [.transform(webTransform), .ignoreIfNull],
      "lastLogin": [.defaultValue(Date()), .transform(dateTransform)],
      "friends": .nonNil
    ]
  }
}
//: You can now use the way below to Desrialize to Object
let json = JSON(jsonData: jsonData)
//let json = JSON(jsonString: jsonString)
do {
  let user = try User(decode: json["data", "users", 1])
} catch {
  print(error)
}

let users = [User](nonNil: json["data", "users"])

//: > nonNil param let you get Non-nil value

if let dict = try? [String: Any](jsonData: jsonData) {
  dict
}

do {
  let user = try User(decode: json["data", "users", 2])
} catch let JSON.Error.outOfBounds(arr: arr, index: index) {
  (index, arr)
}

//: Transforming to json could be done automaticly
users.json
try users.jsonData()
try users.jsonString()

//: Create a JSON is pretty easy

["code": 0, "data": ["users": users]] as JSON

let createJSON = JSON {
  $0["code"]           << 0
  $0["data", "users"]  << users
}
