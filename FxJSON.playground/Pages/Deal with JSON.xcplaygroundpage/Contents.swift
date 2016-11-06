/*:
 > # To use **FxJSON.playground**:
 1. Open **FxJSON.xcworkspace**.
 1. Build the **FxJSON** scheme using iPhone 5s simulator (**Product** → **Build**).
 1. Open **FxJSON** playground in the **Project navigator**.
 1. You can see JSON data in playground **FxJSON** → **Resources** → **json.json**
 
 ### Other Contents:
 - [Overview](Overview)
 - [Using Protocols](Using%20Protocols)
 ----
*/
import FxJSON
import Foundation

//: Assume that you have a json data:

let jsonData = try Data(contentsOf: #fileLiteral(resourceName: "JSON.json"))
let jsonString = String(data: jsonData, encoding: .utf8)
let jsonObject = try JSONSerialization.jsonObject(with: jsonData)

//: ## 1. Initalization
let json = JSON(any: jsonObject)
//let json = JSON(jsonObject)
//let json = JSON(jsonData: jsonData)
//let json = JSON(jsonString: jsonString)

//: ## 2. Deserilization
//: Using Subscript
json["code"]
json["data", "users", 0]

let path: JSON.Index = ["data", "users", 1]
json[path]
json[path, "name"]

//: Use `SupportedType(json)` to deserilize to `SupportedType?`
let code = Int(json["code"])
let whatsUp = String(json[path]["whatsUp"])

//: Using `nonNil` param to get none-Optional type
let userID = Int(nonNil: json[path, "userID"])
let name = String(nonNil: json[path, "name"])

//: Using `throws` param
let admin = try Bool(throws: json[path, "admin"])

do {
  let notExist = try Int(throws: json["notExist"])
} catch let JSON.Error.notExist(dict: dict, key: key) {
  dict
}

//: Using `[SupportedType]`、`[Any]`、`[String: SupportedType]`、 `[String: Any]`
let user = [String: Any](json["data", "users", 0])
let friends = [[String: Any]](nonNil: json[path, "friends"])

let object = try [String: Any](jsonData: jsonData)
//: ## 3. JSON as MutableCollection
//: `JSON` is a MutableCollection, so you may use:
json.count
json.isEmpty
json.first

for subJSON in json {
	// do some thing
}

//: Using `.asArray`, `.asDict` will be more efficient

for subJSON in json.asArray {
	// do some thing
}

for (key, subJSON) in json.asDict {
	// do some thing
}

//: ## 4. Transforming
//: Change `DateTransform.default` to change default date transforming way
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
DateTransform.default = DateTransform.formatter(formatter)
//: Getting date using `DateTransform`
let signUpTime = Date(json[path, "signUpTime"])
let date = Date(JSON(NSTimeIntervalSince1970)[DateTransform.timeIntervalSince(.year1970)])

//: > `DateTransform` use "yyyy-MM-dd'T'HH:mm:ssZ" as default formatter.
//:
//: Using `CustomTransform`, you can choose to use `.toJSON`, `.fromJSON.` or `.both`
let from = CustomTransform<String?, String>.fromJSON {
	if let string = $0 { return "https://\(string)" }
	throw JSON.Error.customTransfrom(source: $0)
}

let website = URL(json[path]["website"][from])

do {
	let code = try Int(throws: json["code"][from])
} catch let JSON.Error.customTransfrom(source: any) {
	any
}
//: > You might use throw JSON.Eror.customTransfrom to handle transforming errors.
//: ## 5. Create a JSON
//: Using Literal
let userJSON: JSON = [
	"userID": userID,
	"name": name,
	"admin": admin
]

//: Using operator <<
let to = CustomTransform<String, String>.toJSON {
  $0.substring(from: $0.index($0.startIndex, offsetBy: 8))
}

let createJSON = JSON {
	$0["code"]             << code
	$0["data", "users"][0] << user
	$0[path]               << JSON {
		$0                     << userJSON
		$0[nonNull: "whatsUp"] << whatsUp
		$0["website"][to]      << website
		$0["signUpTime"]       << signUpTime
		$0["friends"]          << friends
	}
}

json == createJSON
