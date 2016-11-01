//
//  Transform.swift
//  FxJSON
//
//  Created by Frain on 7/5/16.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Frain
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

import Foundation

//MARK: - JSON

extension JSON : JSONSerializable {
	
	public var json: JSON {
		return self
	}
	
	public init(_ object: @autoclosure () throws -> JSONSerializable) {
		do {
			try self = object().json
		} catch {
			self = .error(error)
		}
	}
  
	public init(operate: (Mapper) -> ()) {
		let mapper = Mapper(json: .object([:]), isCreating: true)
		operate(mapper)
		self = mapper.json
	}
  
  public func transformed(operate: (Mapper) -> ()) -> JSON {
    let mapper = Mapper(json: self, isCreating: true)
    operate(mapper)
    return(mapper.json)
  }
	
	public func decode<T : JSONDeserializable>() throws -> T {
		if let v = T(self) { return v }
		throw error ?? Error.deserilize(from: self, to: T.self)
	}
	
	public func map<T : JSONDeserializable, U : JSONSerializable>(
		_ transform: (T) throws -> U) rethrows -> JSON {
		return try T(self).map(transform).map { $0.json } ?? self
	}
  
  public func flatMap<T: JSONDeserializable>(
    _ transform: (T) throws -> JSON) rethrows -> JSON {
    return try T(self).map(transform) ?? self
  }
}

//MARK: - JSONTransformable

extension Array : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard let arr = json.array else { return nil }
		switch Element.self {
		case let T as JSONDeserializable.Type:
			self = arr.flatMap { T.init(JSON(any: $0)) as! Element? }
		case _ as Any.Type:
			self = arr as! [Element]
		default:
			return nil
		}
	}
	
	public var json: JSON {
		return JSON(try JSON.array(self.map { element in
			guard let element = element as? JSONSerializable else {
				throw JSON.Error.unSupportType(type: Element.self)
			}
			return element.json.object
		}))
	}
}

extension Dictionary : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard let dict = json.dict, Key.self is String.Type else { return nil }
		switch Value.self {
		case let T as JSONDeserializable.Type:
			self = dict.flatMap { ($0.0 as! Key, T.init(JSON(any: $0.1)) as! Value?) }
		case _ as Any.Type:
			self = dict.map { ($0.0 as! Key, $0.1 as! Value) }
		default:
			return nil
		}
	}
	
	public var json: JSON {
		guard Key.self is String.Type else {
			return .error(JSON.Error.unSupportType(type: Element.self))
		}
		return JSON(try JSON.object(self.map { (key, value) in
			guard let value = value as? JSONSerializable else {
				throw JSON.Error.unSupportType(type: Element.self)
			}
			return (key as! String, value.json.object)
		}))
	}
}

extension Set : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		self.init()
		guard let T = Element.self as? JSONDeserializable.Type else { return nil }
		for value in json.asArray {
			if let value = T.init(value) as! Element? {
				self.insert(value)
			}
		}
	}
	
	public var json: JSON {
		return JSON(try JSON.array(self.map { element in
			guard let element = element as? JSONSerializable else {
				throw JSON.Error.unSupportType(type: Element.self)
			}
			return element.json.object
		}))
	}
}

extension ImplicitlyUnwrappedOptional : JSONTransformable {
	
	public init?(_ json: JSON) {
		if let T = Wrapped.self as? JSONDeserializable.Type, let value = T.init(json) {
			self = .some(value as! Wrapped)
		} else {
			return nil
		}
	}
	
	public var json: JSON {
		guard Wrapped.self is JSONSerializable.Type else {
			return .error(JSON.Error.unSupportType(type: Wrapped.self))
		}
		if case let .some(v as JSONSerializable) = self { return v.json }
		return nil
	}
}

extension Optional : JSONTransformable {
	
	public init?(_ json: JSON) {
		guard let T = Wrapped.self as? JSONDeserializable.Type else { return nil }
		self = T.init(json) as! Wrapped?
	}
	
	public var json: JSON {
		guard Wrapped.self is JSONSerializable.Type else {
			return .error(JSON.Error.unSupportType(type: Wrapped.self))
		}
		if case let .some(v as JSONSerializable) = self { return v.json }
		return nil
	}
}

extension String : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .string(str) = json else { return nil }
		self = str
	}
	
	public var json: JSON {
		return .string(self)
	}
}

extension Bool : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .bool(boo) = json else { return nil }
		self = boo
	}
	
	public var json: JSON {
		return .bool(self)
	}
}

extension Int : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .number(num) = json else { return nil }
		self = num.intValue
	}
	
	public var json: JSON {
		return .number(NSNumber(value: self))
	}
}

extension Float : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .number(num) = json else { return nil }
		self = num.floatValue
	}
	
	public var json: JSON {
		return .number(NSNumber(value: self))
	}
}

extension Double : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .number(num) = json else { return nil }
		self = num.doubleValue
	}
	
	public var json: JSON {
		return .number(NSNumber(value: self))
	}
}

extension Int8 : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .number(num) = json else { return nil }
		self = num.int8Value
	}
	
	public var json: JSON {
		return .number(NSNumber(value: self))
	}
}

extension Int16 : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .number(num) = json else { return nil }
		self = num.int16Value
	}
	
	public var json: JSON {
		return .number(NSNumber(value: self))
	}
}

extension Int32 : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .number(num) = json else { return nil }
		self = num.int32Value
	}
	
	public var json: JSON {
		return .number(NSNumber(value: self))
	}
}

extension Int64 : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		guard case let .number(num) = json else { return nil }
		self = num.int64Value
	}
	
	public var json: JSON {
		return .number(NSNumber(value: self))
	}
}

extension Date : JSONTransformable, DefaultInitializable {
	
	public init?(_ json: JSON) {
		switch (DateTransform.default, json) {
		case (.formatter(let formatter), .string(let v)):
			self.init()
			guard let date = formatter.date(from: v) else { return nil }
			self = date
		case (.timeIntervalSince(let since), .number(let v)):
			self.init(timeIntervalSince1970: v.doubleValue + since.timeInterval)
		default:
			return nil
		}
	}
	
	public var json: JSON {
		switch DateTransform.default {
		case .formatter(let formatetr):
			return .string(formatetr.string(from: self))
		case .timeIntervalSince(let since):
			return .number(NSNumber(value: timeIntervalSince1970 - since.timeInterval))
		}
	}
}

extension URL : JSONTransformable {
	
	public init?(_ json: JSON) {
		guard let value = String(json)?
      .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
      else { return nil }
		self.init(string: value)
	}
	
	public var json: JSON {
		return .string(self.absoluteString)
	}
}

extension NSNull : JSONSerializable {
	
	public var json: JSON {
		return JSON()
	}
}

//MARK: - Transform

public enum CustomTransform<JSONObject: JSONTransformable, Object: JSONTransformable>: Transform {
	
	case fromJSON((JSONObject) throws -> Object)
	case toJSON((Object) throws -> JSONObject)
	case both(fromJSON: (JSONObject) throws -> Object, toJSON: (Object) throws -> JSONObject)
	
	public var jsonObjectType: JSONTransformable.Type {
		return JSONObject.self
	}
	
	public var objectType: JSONTransformable.Type {
		return Object.self
	}
	
	public var fromJSONFunc: Transform.Func? {
		switch self {
		case let .fromJSON(fromJSONFunc), let .both(fromJSON: fromJSONFunc, toJSON: _):
			return { try fromJSONFunc($0 as! JSONObject) }
		default:
			return nil
		}
	}
	
	public var toJSONFunc: Transform.Func? {
		switch self {
		case let .toJSON(toJSONFunc), let .both(fromJSON: _, toJSON: toJSONFunc):
			return { try toJSONFunc($0 as! Object) }
		default:
			return nil
		}
	}
}

public enum DateTransform: Transform {
	
	public enum Since {
		
		case year1970
		case now
		case referenceDate
		case date(Date)
		
		var timeInterval: TimeInterval {
			switch self {
			case .year1970: return 0
			case .now: return Date().timeIntervalSince1970
			case .referenceDate: return NSTimeIntervalSince1970
			case .date(let date): return date.timeIntervalSince1970
			}
		}
	}
	
	case formatter(DateFormatter)
	case timeIntervalSince(Since)
	
	public static var `default`: DateTransform = {
		$0.dateFormat = "yyyy-MM-dd HH:mm:ss"
		$0.timeZone = TimeZone.current
		return .formatter($0)
	}(DateFormatter())
	
	public var jsonObjectType: JSONTransformable.Type {
		switch self {
		case .formatter: return String.self
		case .timeIntervalSince: return Double.self
		}
	}
	
	public var objectType: JSONTransformable.Type {
		switch DateTransform.default {
		case .formatter: return String.self
		case .timeIntervalSince: return Double.self
		}
	}
	
	func setTransform(from: DateTransform, to: DateTransform) -> Transform.Func {
		let deserialize = { (jsonTransformable: JSONTransformable) throws -> Date in
			switch from {
			case .formatter(let formatter):
				let dateString = jsonTransformable as! String
				if let date = formatter.date(from: dateString) { return date }
				throw JSON.Error.formatter(format: formatter.dateFormat, value: dateString)
			case .timeIntervalSince(let since):
				let dateNum = jsonTransformable as! TimeInterval
				return Date(timeIntervalSince1970: dateNum + since.timeInterval)
			}
		}
		let serialize = { (date: Date) -> JSONTransformable in
			switch to {
			case .formatter(let formatter): return formatter.string(from: date)
			case .timeIntervalSince(let since): return date.timeIntervalSince1970 - since.timeInterval
			}
		}
		return { serialize(try deserialize($0)) }
	}
	
	public var fromJSONFunc: Transform.Func? {
		return setTransform(from: self, to: DateTransform.default)
	}
	
	public var toJSONFunc: Transform.Func? {
		return setTransform(from: DateTransform.default, to: self)
	}
}
