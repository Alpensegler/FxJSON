/*:
> # To use **FxJSON.playground**:
1. Open **FxJSON.xcworkspace**.
1. Build the **FxJSON** scheme (**Product** → **Build**).
1. Open **FxJSON** playground in the **Project navigator**.
1. Show the Debug Area (**View** → **Debug Area** → **Show Debug Area**).

[Deal with JSON](@previous)
*/
import FxJSON
import Foundation
/*:
Assume that you have a json data like this:
*/
var json: JSON = [
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
/*:
JSONMapable Protocol expected type that all of its propertes are Optional or having default value.
*/
struct User: JSONMappable {
	
	var userID: Int64!
	var name: String!
	var admin: Bool = false
	var website: NSURL?
	var friends: [User]?
	var whatsUp: String?
	var signUpTime: NSDate?
	var lastLoginTime = NSDate()
	
	mutating func mapping(inout json: JSON) {
		userID			<> json["uid"]
		name			<> json["name"]
		admin			<> json["admin"]
		website			<> json["website"]
		friends			<> json[noneNull: "friends"]
		whatsUp			<> json[noneNull: "whatsUp"]
		signUpTime		<< json["signUpTime"][DateTF()]
		lastLoginTime	>> json["lastLoginTime"][DateTF()]
	}
}

let users = User(json["data"]["users"][1])
print(users)
print(users.json)
/*:
For those type that have property you dont want to use Optional, use JSONDeinitable protocol.
*/
struct WebData: JSONDecodable {
	
	enum ErrorCode: Int {
		case none = 0
		case serverError = 1
	}
	
	let error: ErrorCode
	let data: [String : [User]]
	
	init(json: JSON) throws {
		error	= try json["code"]<
		data	= try json["data"]<
	}
}
//: Using JSONInitable protocol can easly serilize a custom Object to a json.
extension WebData: JSONEncodable {
	
	func mapping(inout json: JSON) {
		error	>> json["code"]
		data	>> json["data"]
	}
}

guard let webData = WebData(json) else { fatalError() }
debugPrint(webData.json["data", "users", 0])

// Now you can creat a json in this two way, its the same:
let createdJSONWayOne = JSON {
	0		>> $0["code"]
	users	>> $0["data", "users"]
}

let createdJSONWayTwo: JSON = ["code": 0, "data": ["users": users]]

createdJSONWayOne == createdJSONWayTwo
//: Printable, just ignore it.
protocol MirrorStringConvertable: CustomDebugStringConvertible {
	
	var tabNumber: Int { get }
}

extension MirrorStringConvertable {
	
	var tabNumber: Int { return 3 }
	
	var debugDescription: String {
		let mirror = Mirror(reflecting: self)
		var s = "\n----" + (mirror.displayStyle.map { " \($0)" } ?? "")
		s += " \(mirror.subjectType) ----\n"
		for case let (label, value) in mirror.children {
			s += label.map { v in
				var l = v.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
				l = tabNumber - (l % 5 == 0 ? l / 5 - 1 : l / 5)
				return (0...l).reduce(v) { $0.0 + "\t" }
			} ?? ""
			s += "\(value)\n"
		}
		return s
	}
}

extension User : MirrorStringConvertable {}
extension WebData : MirrorStringConvertable {}