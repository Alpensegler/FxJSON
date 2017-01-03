import FxJSON
import Foundation
let json = [
  "kanme": "frain",
  "age": 21,
  "gender": "male",
  "favorite": ["game": "animation"]
] as JSON

let trans = CustomTransform.fromJSON { (json: String) -> String in
  return json + "aaa"
}

class Some: JSONDecodable, JSONEncodable, DefaultInitable {
  
  let name: String = ""
  let age: Int = 0
  let gender: String = ""
  let favorite = Favorite(game: "")
  
  required init() { }
  
  class func specificOptions() -> [String: SpecificOption] {
    return ["name": ["kanme", .transform(trans), .nonNil],
      //"animation": .index(["favorite", "game"])
    ]
  }
}

struct Favorite: JSONDecodable, JSONSerializable {
  let game: String
  
  var json: JSON {
    return .null
  }
}

class Some2: Some {
  let animation: String = "aaa"
  
  override class func specificOptions() -> [String: SpecificOption] {
    var option = super.specificOptions()
    option["animation"] = .index(["favorite", "game"])
    return option
  }
}

do {
  let some = try Some(decode: json)
  print(some.json)
} catch {
  print(error)
}

if let some2 = Some2(json) {
  print(some2.animation)
  print(some2.json)
}

enum SomeEnum: String, JSONDecodable {
  case hahaha
  case heiheihei
  
  init() {
    self = .hahaha
  }
}

try SomeEnum(decode: "hahaha")
