import FxJSON
import Foundation

public extension JSON {
	
	func save(as key: String, to userDefaults: UserDefaults = UserDefaults.standard) -> Bool {
		userDefaults.set(object, forKey: key)
		return userDefaults.synchronize()
	}
	
	static func get(key: String, from userDefaults: UserDefaults = UserDefaults.standard) -> JSON {
		guard let object = userDefaults.object(forKey: key) else { return JSON() }
		var json = JSON()
		json.object = object
		return json
	}
}

public extension JSONDeserializable where Self: JSONSerializable {
	
	func save(as key: String, to userDefaults: UserDefaults = UserDefaults.standard) -> Bool {
		return json.save(as: key, to: userDefaults)
	}
	
	static func get(key: String, from userDefaults: UserDefaults = UserDefaults.standard) -> Self? {
		let json = JSON.get(key: key, from: userDefaults)
		return Self.init(json)
	}
}

let null = NSNull()

let data = try! JSONSerialization.data(withJSONObject: null, options: [])