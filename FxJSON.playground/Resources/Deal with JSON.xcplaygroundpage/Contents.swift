/*:
> # To use **FxJSON.playground**:
1. Open **FxJSON.xcworkspace**.
1. Build the **FxJSON** scheme (**Product** → **Build**).
1. Open **FxJSON** playground in the **Project navigator**.
1. Show the Debug Area (**View** → **Debug Area** → **Show Debug Area**).

[Protocols](@next)
*/
import FxJSON
import Foundation
//: ## 1. Initalization
let jsonObject: [String: Any] = [
	"code": 0,
	"data": [
		"users": [
			[
				"uid": 1,
				"name": "FrainTest",
				"admin": true,
				"website": NSNull(),
				"signUpTime": "2016-03-04 11:23:30",
			],
			[
				"uid": 3,
				"name": "Frain",
				"admin": false,
				"website": "https://github.com/FrainL",
				"whatsUp": "buzy",
				"signUpTime": "2016-06-19 21:31:31"
			]
		]
	]
]

let data = try JSONSerialization.data(withJSONObject: jsonObject)

let json = JSON(jsonObject)
let jsonByObject = JSON(data: data)
//: ## 2. Deserilization
//: ### Using Subscript
json["code"]
json["data", "users", 0]

let path: JSON.Index = ["data", "users", 0]
json[path]
json[path, "name"]
//: ### deserilize to nomal type
//:way one (those types are all optional)
let code = Int(json["code"])
let website = String(json[path]["website"])
//:> use value param to get none-Optional type
let uid = Int(noneNull: json[path]["uid"])

let admin = Bool(json[path]["admin"])
//:way two: using operator <
let name = try json[path].decode() as String
let user = try json["data", "users", 1]< as [String: Any]
//: ### Getting date by using DateTF

//:getting date from StringJSON(use "yyyy-MM-dd HH:mm:ss" and defaultTimeZone as default formatter)

////:getting date from NumberJSON(use .since1970 as default formatter)
//guard let dateThree = NSDate(JSON(0)[DateTF(timeInterval: .year1970)]) else { f//guard let dateFour = NSDate(JSON(NSTimeIntervalSince1970)[DateTF.init(timeInterval: .referenceDate)]) else { fatalError() }
// fatalError() }
////:For those StringJSON you may need some transfrom, simply use map function.
//let time: JSON = ["time": "2016-08-//
////func setCorrectForm(s: String) -> String {
////	guard let to = s.rangeOfString("(")?.startIndex,
////		let from = s.rangeOfString(")")?.endIndex else { return s }
////	return s.substringToIndex(to) + " " + s.substringFromIndex(from)
////}
////
////let d = NSDate(time["time"].map(setCorrectForm))
//////: ## 3. Error handling
//3. Error handling
////: ### Subscript Error
//if let num//	// do something
////} else {
////	// do something
////	json[0].error?.localizedDescription
////	print(json.type)
////}
//rint(json.type)
////}
////: ### Getter Error
//do {
//	let num: Int //} catch let error as NSError {
////	// do something
////	error.localizedDescription
////}
//////: ## 4. For-in
//
//}
//////: ## 4. For-in
////: If JSON is an object
//for (ke//	// do something
////}
//////: If JSON is an array
////for v in json.asArray {
////	// do something
////}
//////: ## 5. Creat/change a JSON
//////: ### Using Literal
////
//ON
////: ### Using Literal
//
//let userJS//	"name": name,
////	"admin": admin
////]
//////: ### Using operator >>
//]
////: ### Using operator >>
//var creatJSON =//	user	>> $0["data", "users", 1]
////}
////
////creatJSON.transfrom {
////	userJSON	>> $0[path]
////	()			>> $0[noneNull: path, "signature"]
////	website		>> $0[path, "website"]
////	dateOne		>> $0[path, "signUpTime"][DateTF()]
////}
////
////creatJSON == json
//eTF()]
//}
//
//creatJSON == json
