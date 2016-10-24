import FxJSON
import Curry
import Runes

let json: JSON = [
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

let user1 = json["data","users",0]
let user2 = json["data","users"]

DateTransform.defaultFormatter = {
    $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
    $0.timeZone = TimeZone.autoupdatingCurrent
    return $0
}(DateFormatter())

struct User : JSONDecodable, JSONEncodable {
    
    var userID: Int64
    var name: String
    var admin: Bool = false
    var website: URL?
    var whatsUp: String?
    var signUpTime: Date?
    
    init(json: JSON) throws {
        userID =        try json[1]["uid"].decode()
        name =          try json[1]["name"].decode()
        signUpTime =    try json[1]["signUpTime"][DateTransform()].decode()
    }
    
    func encode(_ json: (inout JSON)) {
        userID      >> json["uid"]
        name        >> json["name"]
        website     >> json["admin"]
        whatsUp     >> json["website"]
        signUpTime  >> json["signUpTime"][DateTransform()]
    }
}

let user = User(user2)

dump(user)
print(user.json)
