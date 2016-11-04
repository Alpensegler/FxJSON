/*:
> # To use **FxJSON.playground**:
1. Open **FxJSON.xcworkspace**.
1. Build the **FxJSON** scheme using iPhone 5s simulator (**Product** → **Build**).
1. Open **FxJSON** playground in the **Project navigator**.

[Deal with JSON](@previous)
*/
import FxJSON
import Foundation
import UIKit
/*:
Assume that you have a json data like this:
*/
let json: JSON = [
  "code": 0,
  "data": [
    "users": [
      [
        "userID": 0,
        "name": "Admin",
        "admin": true,
        "signUpTime": "1996-03-12 00:00:00"
      ],
      [
        "userID": 1,
        "name": "Frain",
        "admin": false,
        "website": "https://github.com/FrainL",
        "signUpTime": "2016-04-22 21:31:31",
        "friends": [
          ["userID": 2, "name": "box", "admin": false],
          ["userID": 2, "name": "sky", "admin": false]
        ]
      ]
    ]
  ]
]

let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
DateTransform.default = DateTransform.formatter(formatter)

//: ## 1. JSONDecodable, JSONEncodable

//: Struct adopting JSONDecodable

struct BasicStruct : JSONDecodable {
  let userID: Int
  let name: String
  let admin: Bool
  let signUpTime: Date?
  
  init(decode json: JSON) throws {
    userID      = try json["userID"]<
    name        = try json["name"]<
    admin       = try json["admin"]<
    signUpTime  = try json["signUpTime"]<
  }
}

let admin = BasicStruct(json["data", "users", 0])

//: Class adopting JSONDecodable

class BasicClass : JSONDecodable, JSONEncodable {
  let userID: Int
  let name: String
  let admin: Bool
  let signUpTime: Date?
  
  required init(decode json: JSON) throws {
    userID      = try json["userID"]<
    name        = try json["name"]<
    admin       = try json["admin"]<
    signUpTime  = try json["signUpTime"]<
  }
  
  func encode(mapper: JSON.Mapper) {
    mapper["userID"]              << userID
    mapper["name"]                << name
    mapper["admin"]               << admin
    mapper[nonNull: "signUpTime"] << signUpTime
  }
}

let basicClass = BasicClass(json["data", "users", 0])

class UserClass : BasicClass {
  let website: URL?
  let friends: [BasicClass]
  
  required init(decode json: JSON) throws {
    website = try json["website"]<
    friends = try json["friends"]<
    try super.init(decode: json)
  }
  
  override func encode(mapper: JSON.Mapper) {
    mapper[nonNull: "website"]  << website
    mapper["friends"]           << friends
    super.encode(mapper: mapper)
  }
}

let userClass = UserClass(json["data", "users", 1])

userClass?.json

//: ## 2. JSONMappable

class Basic: JSONMappable {
  var userID: Int!
  var name: String!
  var admin: Bool = false
  var signUpTime: Date?
  
  required init() {}
	
	func map(mapper: JSON.Mapper) { }
}

Basic(json["data", "users", 0])?.json

class User : Basic {
  var website: URL?
	var friends: [Basic]?
	var lastLoginTime = Date()
	
  override func map(mapper: JSON.Mapper) {
    admin					>< mapper
		website				<> mapper["website"]
		lastLoginTime	>> mapper["lastLoginTime"]
		signUpTime		<> mapper["signUpTime"][DateTransform.default]
  }
}

do {
	let user = try User(throws: json["data", "users", 1])
} catch {
	print(error)
}

//: ## 3.  JSONConvertable、JSONTransformable

extension UIColor : JSONConvertable {
	public static func convert(from json: JSON) -> Self? {
		guard let hex = Int(json) else { return nil }
		let r = (CGFloat)((hex >> 16) & 0xFF)
		let g = (CGFloat)((hex >> 8) & 0xFF)
		let b = (CGFloat)(hex & 0xFF)
		return self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
	}
}

let color = UIColor(JSON(0xFF0000))

enum ErrorCode : Int, JSONTransformable {
	case noError
	case netWorkError
}

let errorCode = ErrorCode(json["code"])