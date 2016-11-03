import FxJSON
import Foundation

let i = 0 as Any

//let some = type(of: i)

struct User: JSONDecodable {
  
  let gender: Gender
	let website: URL
  let signUpTime: Date
  
  enum Gender: Int, JSONTransformable {
    case boy
    case girl
  }
  
  init(decode json: JSON) throws {
    gender      = try json["gender"]<
    website     = try json["website"]<
    signUpTime  = try json["signUpTime"][DateTransform.timeIntervalSince(.year1970)]<
  }
}

extension User: JSONEncodable { }

extension User {
  
  func encode(mapper: JSON.Mapper) {
    mapper["gender"] << gender
    mapper["website"] << website
    mapper["signUpTime"] << signUpTime
  }
}
