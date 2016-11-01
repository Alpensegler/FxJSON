import FxJSON

let json: JSON = [
	"code": 0,
	"data": [
		"users": [
			[
				"userID": 0,
				"name": "Admin",
				"admin": true,
				"website": NSNull(),
				"signUpTime": "1996-03-12 00:00:00",
			],
			[
				"userID": 1,
				"name": "Frain",
				"admin": false,
				"website": "https://github.com/FrainL",
				"whatsUp": "buzy",
				"signUpTime": "2016-04-22 21:31:31",
				"friends": [
					["userID": 2,"name": "box","admin": false],
					["userID": 2,"name": "sky","admin": false]
				]
			]
		]
	]
]

struct User: JSONMappable {
	var userID: Int64!
	var name: String!
	var admin: Bool = false
	var whatsUp: String?
	var website: URL?					//URL 自动转化
	var signUpTime: Date?			//Date 通过 DateTransform 转化
	var friends: [User]?			//自己的数据结构也可以转化
//  var lastLoginDate = Date()
}

extension User {
	
	mutating func map(mapper: JSON.Mapper) {
		whatsUp       <> mapper["sign"]
    signUpTime    << mapper["signUpTime"]
//    lastLoginDate >> mapper["lastLoginDate"]
    admin         >< mapper
	}
}

do {
  let user = try User(throws: json["data", "users", 1])
  print(user)
  print(user.json)
} catch {
	print(error)
}
