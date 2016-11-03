/*:
> # To use **FxJSON.playground**:
1. Open **FxJSON.xcworkspace**.
1. Build the **FxJSON** scheme using iPhone 5s simulator (**Product** → **Build**).
1. Open **FxJSON** playground in the **Project navigator**.
1. Show the Debug Area (**View** → **Debug Area** → **Show Debug Area**).

[Protocols](@next)
*/
import FxJSON
import Foundation
//: ## 1. Initalization
let jsonObject: [String: Any] = [
	"code": "0",
	"data": [
		"users": [
			[
				"userID": 0,
				"name": "Admin",
				"admin": true,
				"website": NSNull(),
				"signUpTime": "1996-03-12 00:00:00"
				],
			[
				"userID": 1,
				"name": "Frain",
				"admin": false,
				"website": "https://github.com/FrainL",
				"signUpTime": "2016-04-22 21:31:31",
				"friends": [
					["userID": 2,"name": "box","admin": false],
					["userID": 2,"name": "sky","admin": false]
				]
			]
		]
	]
]

let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
let jsonString = String(data: jsonData, encoding: .utf8)

let json = JSON(jsonObject)
//let json = JSON(any: jsonObject)
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
guard let userID = Int(json[path, "userID"]) else { fatalError() }
let website = URL(json[path]["website"])
let whatsUp = String(json[path]["whatsUp"])
//: Using `noneNull` param to get none-Optional type
let name = String(noneNull: json[path, "name"])
//: Using `throws` param
let admin = try Bool(throws: json[path, "admin"])

do {
  let notExist = try Int(throws: json["notExist"])
} catch let JSON.Error.notExist(dict: dict, key: key) {
  dict
}
//: Using `[SupportedType]`、`[Any]`、`[String: SupportedType]`、 `[String: Any]`
let user = [String: Any](json["data", "users", 0])
let friends = [[String: Any]](noneNull: json[path, "friends"])

//: ## 3. JSON as MutableCollection
for subJSON in json {
	// do some thing
}

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

//: Getting date using DateTransform(use "yyyy-MM-dd'T'HH:mm:ssZ" as default formatter if it wasn't change)
let signUpTime = Date(json[path, "signUpTime"])
let date = Date(JSON(NSTimeIntervalSince1970)[DateTransform.timeIntervalSince(.year1970)])

//: Using `CustomTransform`, you can choose to use `.toJSON`, `.fromJSON.` or `.both`
let from = CustomTransform<String, Int>.fromJSON {
	if let number = Int($0) { return number }
	throw JSON.Error.customTransfrom(source: $0)
}
let to = CustomTransform<String, Int>.toJSON { "\($0)" }
let code = Int(json["code"][from])

do {
	let code = try Int(throws: json[path, "name"][from])
} catch let JSON.Error.customTransfrom(source: any) {
	any
}

//: ## 5. Creat/change a JSON
//: Using Literal
let userJSON = [
	"userID": userID,
	"name": name,
	"admin": admin
] as JSON

//: Using operator <<

let createJSON = JSON {
	$0["code"][to] << code
	$0["data", "users", 0] << user
	$0[path] << JSON {
		$0 << userJSON
		$0[noneNull: "whatsUp"] << whatsUp
		$0["website"] << website
		$0["signUpTime"] << signUpTime
		$0["friends"] << friends
	}
}

json == createJSON
