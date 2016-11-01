//
//  JSON.swift
//  FxJSON
//
//  Created by Frain on 7/2/16.
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

public enum JSON {
    
	case object([String: Any])
	case array([Any])
	case string(String)
	case number(NSNumber)
	case bool(Bool)
	case error(Swift.Error)
	case null
}

public extension JSON {

	var object: Any {
		switch self {
		case let .object(any): return any
		case let .array(any): return any
		case let .string(any): return any
		case let .number(any): return any
		case let .bool(any): return any
		case let .error(any): return any
		default: return NSNull()
		}
	}
	
	init() {
		self = .null
	}
	
	init(any: Any) {
		switch any {
		case let dic as [String: Any]:
			self = .object(dic)
		case let arr as [Any]:
			self = .array(arr)
		case let str as String:
			self = .string(str)
		case let num as NSNumber:
			if CFGetTypeID(num) == CFBooleanGetTypeID() {
					self = .bool(num.boolValue)
			} else {
					self = .number(num)
			}
		case _ as NSNull:
			self = .null
		case let err as Swift.Error:
			self = .error(err)
		case let any as JSONSerializable:
			self = any.json
		default:
			self = .error(Error.unSupportType(type: type(of: any)))
		}
	}
	
	var type: String {
		switch self {
		case .object: return "Object"
		case .array: return "Array"
		case .string: return "String"
		case .number: return "Number"
		case .bool: return "Bool"
		case .error: return "Error"
		case .null: return "Null"
		}
	}
	
	var isNull: Bool {
		if case .null = self { return true }
		return false
	}
	
	var isError: Bool {
		if case .error = self { return true }
		return false
	}
	
	var error: Swift.Error? {
		if case let .error(error) = self { return error }
		return nil
	}
}

//MARK: - Error handling

public extension JSON {
    
	enum Error: Swift.Error, CustomStringConvertible {
		
		case initalize(Swift.Error)
		case unSupportType(type: Any.Type)
		case encodeToData(wrongObject: Any)
		case notExist(dict: [String: Any], key: String)
		case wrongType(subscript: JSON, key: Index)
		case outOfBounds(arr: [Any], index: Int)
		case deserilize(from: JSON, to: Any.Type)
		case formatter(format: String, value: String)
		case customTransfrom(source: Any)
		
		public var description: String {
			switch self {
			case .initalize(let error):
				return "Initalize error, \(error))"
			case .unSupportType(type: let type):
				return "Type: \(type) is unsupport"
			case .encodeToData(wrongObject: let any):
				return "Wrong object: \(any) encoding to JSON data"
			case .notExist(dict: let dict, key: let key):
				return "Key: \"\(key)\" not exist, dict is: \(dict)"
			case .wrongType(subscript: let json, key: let key):
				return "Cannot subscrpit key: \(key) to \(json.debugDescription)"
			case .outOfBounds(arr: let arr, index: let index):
				return "Subscript \(index) to \(arr) is out of bounds"
			case .deserilize(from: let json, to: let type):
				return "Cannot deserilize to \(type), json is \(json.debugDescription)"
			case .formatter(format: let format, value: let value):
				return "Cannot phrase \(value) with \(format)"
			case .customTransfrom(source: let source):
				return "CustomTransfrom error, source: \(source)"
			}
		}
	}
}

// MARK: - ExpressibleByLiteral

extension JSON : ExpressibleByDictionaryLiteral {
	
	public init(dictionaryLiteral elements: (String, JSONSerializable)...) {
		var dict = [String: Any](minimumCapacity: elements.count)
		for element in elements { dict[element.0] = element.1.json.object }
		self = .object(dict)
	}
}

extension JSON : ExpressibleByArrayLiteral {
	
	public init(arrayLiteral elements: JSONSerializable...) {
		self = .array(elements.map { $0.json.object })
	}
}

extension JSON : ExpressibleByStringLiteral {
	
	public init(stringLiteral value: StringLiteralType) {
		self = .string(value)
	}
	
	public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
		self = .string(value)
	}
	
	public init(unicodeScalarLiteral value: StringLiteralType) {
		self = .string(value)
	}
}

extension JSON : ExpressibleByIntegerLiteral {
	
	public init(integerLiteral value: IntegerLiteralType) {
		self = .number(NSNumber(value: value))
	}
}

extension JSON : ExpressibleByFloatLiteral {
	
	public init(floatLiteral value: FloatLiteralType) {
		self = .number(NSNumber(value: value))
	}
}

extension JSON : ExpressibleByBooleanLiteral {
	
	public init(booleanLiteral value: BooleanLiteralType) {
		self = .bool(value)
	}
}

extension JSON : ExpressibleByNilLiteral {
	
	public init(nilLiteral: ()) {
		self.init()
	}
}

//MARK: - convert to and from jsonData and jsonString

public extension JSON {
    
	init(data: Data?, options: JSONSerialization.ReadingOptions = []) {
		guard let data = data else { self.init(); return }
		do {
			let object = try JSONSerialization.jsonObject(with: data, options: options)
			self.init(any: object)
		} catch {
			self.init(JSON.error(JSON.Error.initalize(error)))
		}
	}
	
	init(jsonString: String?, options: JSONSerialization.ReadingOptions = []) {
		self.init(data: jsonString?.data(using: String.Encoding.utf8), options: options)
	}
	
	func data(withOptions: JSONSerialization.WritingOptions = []) throws -> Data {
		guard JSONSerialization.isValidJSONObject(object) else {
			throw error ?? Error.encodeToData(wrongObject: object)
		}
		return try JSONSerialization.data(withJSONObject: object, options: withOptions)
	}
    
	func jsonString(withOptions: JSONSerialization.WritingOptions = [],
                  encoding: String.Encoding = String.Encoding.utf8) -> String {
		switch self {
		case .object, .array:
			do {
				let data = try self.data(withOptions: withOptions)
				return String(data: data, encoding: encoding) ?? "Encode error"
			} catch {
				return "\(error)"
			}
		case .string(let str):
			return "\"\(str)\""
		case .number(let num):
			return num.description
		case .bool(let boo):
			return boo.description
		case .error(let error):
			return "\(error)"
		case .null:
			return "null"
		}
	}
}

//MARK: - StringConvertible

extension JSON : CustomStringConvertible, CustomDebugStringConvertible {
    
	public var description: String {
		return jsonString(withOptions: .prettyPrinted)
	}
	
	public var debugDescription: String {
		return type + ": " + jsonString()
	}
}

//MARK: - Equatable

extension JSON : Equatable { }

public func ==(lhs: JSON, rhs: JSON) -> Bool {
	switch (lhs, rhs) {
	case let (.object(l as NSDictionary), .object(r as NSDictionary)):
		return l == r
	case let (.array(l as NSArray), .array(r as NSArray)):
		return l == r
	case let (.string(l), .string(r)):
		return l == r
	case let (.bool(l), .bool(r)):
		return l == r
	case let (.number(l), .number(r)):
		return l == r
	case (.null, .null):
		return true
	default:
		return false
	}
}

//MARK: - For - in

public extension JSON {
	
	var dict: [String: Any]? {
		guard case let .object(dic) = self else { return nil }
		return dic
	}
	
	var array: [Any]? {
		guard case let .array(arr) = self else { return nil }
		return arr
	}
	
	var asDict: LazyMapCollection<[String: Any], (key: String, value: JSON)> {
		return (dict ?? [:]).lazy.map { ($0.0, JSON(any: $0.1)) }
	}
    
	var asArray: LazyMapCollection<[Any], JSON> {
		return (array ?? []).lazy.map { JSON(any: $0) }
	}
}

//MARK: - Dictionary extension

extension Dictionary {
	
	func map<T, U>(_ f: (Key, Value) throws -> (key: U, value: T)) rethrows -> [U: T] {
		var dict = [U: T](minimumCapacity: self.count)
		for (key, value) in self {
			let (key, value) = try f(key, value)
			dict[key] = value
		}
		return dict
	}
	
	func flatMap<T, U>(_ f: (Key, Value) -> (key: U, value: T?)) -> [U: T] {
		var dict = [U: T](minimumCapacity: self.count)
		for (key, value) in self {
			if case let (key, .some(value)) = f(key, value) {
				dict[key] = value
			}
		}
		return dict
	}
}
