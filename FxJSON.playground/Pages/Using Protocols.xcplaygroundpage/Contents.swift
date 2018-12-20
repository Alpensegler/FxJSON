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

//: Assume that you have a json data like this:

let data = try? Data(contentsOf: #fileLiteral(resourceName: "JSON.json"))
let json = JSON(jsonData: data)

let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
let transform = DateTransform.formatter(formatter)
DateTransform.default = transform

//: ## 1. JSONDecodable, JSONEncodable

//: Struct adopting JSONDecodable

struct BasicStruct: JSONDecodable {
  let userID: Int64
  let name: String
  let admin: Bool
  let signUpTime: Date?
  
//  init(decode json: JSON) throws {
//    userID      = try json["userID"]<
//    name        = try json["name"]<
//    admin       = try json["admin"]<
//    signUpTime  = try json["signUpTime"]<
//  }
}

extension BasicStruct {
  static func specificOptions() -> [String: SpecificOption] {
    return [
      "userID": ["userID", .nonNil],  // same as .index("userID")
      "admin": [.defaultValue(true), .ignore],
      "signUpTime": [.transform(transform), .ignoreIfNull]
    ]
  }
}

let admin = BasicStruct(json["data", "users", 0])

//: Class adopting JSONDecodable

class BasicClass: JSONDecodable, JSONEncodable {
  let userID: Int64
  let name: String
  let admin: Bool
  let signUpTime: Date?
  
  required init(decode json: JSON) throws {
    userID      = try json["userID"]<
    name        = try json["name"]<
    admin       = try json["admin"]<
    signUpTime  = try json["signUpTime"]<
  }
  
  func encode(mapper: JSON.Wrapper) {
    mapper["userID"]                    << userID
    mapper["name"]                      << name
    mapper["admin"]                     << admin
    mapper[ignoreIfNull: "signUpTime"]  << signUpTime
  }
}

let basicClass = BasicClass(json["data", "users", 0])

class UserClass: BasicClass {
  let website: URL?
  let friends: [BasicClass]
  
  required init(decode json: JSON) throws {
    website = try json["website"]<
    friends = try json["friends"]<
    try super.init(decode: json)
  }
  
  override func encode(mapper: JSON.Wrapper) {
    mapper[ignoreIfNull: "website"]  << website
    mapper["friends"]                << friends
    super.encode(mapper: mapper)
  }
}

let userClass = UserClass(json["data", "users", 1])

userClass?.json

//: ## 3.  JSONConvertable、JSONCodable

extension UIColor: JSONConvertable {
	public static func convert(from json: JSON) -> Self? {
		guard let hex = Int(json) else { return nil }
		let r = (CGFloat)((hex >> 16) & 0xFF)
		let g = (CGFloat)((hex >> 8) & 0xFF)
		let b = (CGFloat)(hex & 0xFF)
		return self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
	}
}

let color = UIColor(0xFF00FF as JSON)

enum ErrorCode: Int, JSONCodable {
	case noError
	case netWorkError
}

let errorCode = ErrorCode(json["code"])
