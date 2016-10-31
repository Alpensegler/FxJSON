//
//  Protocols.swift
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

typealias Pointer = UnsafePointer<Int8>

//MARK: - JSONSerializable

public protocol JSONSerializable {
	
	var json: JSON { get }
}

public extension JSONSerializable {
	
	func data(withOptions: JSONSerialization.WritingOptions = []) throws -> Data {
		return try json.data(withOptions: withOptions)
	}
  
  func jsonString(withOptions: JSONSerialization.WritingOptions = [],
                  encoding: String.Encoding = String.Encoding.utf8) -> String {
		return json.jsonString(withOptions: withOptions, encoding: encoding)
	}
}

public extension JSONSerializable
  where Self: RawRepresentable, Self.RawValue: JSONSerializable {
  
  var json: JSON {
    return rawValue.json
  }
}

//MARK: - JSONDeserializable

public protocol JSONDeserializable {
	
    init?(_ json: JSON)
}

public extension JSONDeserializable {
	
	init?(data: Data?, options: JSONSerialization.ReadingOptions = []) {
		let json = JSON.init(data: data, options: options)
		self.init(json)
	}
    
	init?(jsonString: String?, options: JSONSerialization.ReadingOptions = []) {
    let json = JSON.init(jsonString: jsonString, options: options)
    self.init(json)
	}
}

public extension JSONDeserializable
  where Self: RawRepresentable, Self.RawValue: JSONDeserializable {
  
  init?(_ json: JSON) {
    guard let raw = RawValue(json) else { return nil }
    self.init(rawValue: raw)
  }
}

//MARK: - DefaultInitializable

public protocol DefaultInitializable {
	
	init()
}

public extension JSONDeserializable where Self: DefaultInitializable {
	
	init(noneNull json: JSON) {
		self = Self.init(json) ?? Self.init()
	}
}

//MARK: - JSONTransformable

public typealias JSONTransformable = JSONDeserializable & JSONSerializable

extension JSONDeserializable where Self: JSONSerializable {
    
	static var size: Int {
		return MemoryLayout<Self>.size
	}
	
	static func offsetToAlignment(_ value: Int) -> Int {
		let align = MemoryLayout<Self>.alignment
		let m = value % align
		return m == 0 ? 0 : (align - m)
	}
	
	static func code(_ value: JSONDeserializable, into pointer: Pointer) {
		pointer.withMemoryRebound(to: Self.self, capacity: 1, { $0 })
		.pointee = value as! Self
	}
}

//MARK: - JSONConvertable

public protocol JSONConvertable : JSONDeserializable {
    
  static func convert(from json: JSON) -> Self?
}

public extension JSONConvertable {
    
	init?(_ json: JSON) {
		guard let v = Self.convert(from: json) else { return nil }
		self = v
	}
}

//MARK: - JSONDecodable

public protocol JSONDecodable : JSONDeserializable {
	
	init(decode json: JSON) throws
}

public extension JSONDecodable {
	
	init?(_ json: JSON) {
		guard let value = try? Self.init(decode: json) else { return nil }
		self = value
	}
}

//MARK: - JSONEncodable

public protocol JSONEncodeable : JSONSerializable {
	
	func encode(mapper: JSON.Mapper)
}

public extension JSONEncodeable {
	
	func encode(mapper: JSON.Mapper) {
		let children = Mirror(reflecting: self).children
		for (key, value) in children {
      guard let key = key, let serializable = value as? JSONSerializable else {
        mapper.json = .error(JSON.Error.unSupportType(type: type(of: value)))
        return
      }
			mapper.json[create: .key(.key(key))] = serializable.json
		}
	}
  
	var json: JSON {
		return JSON.init(operate: encode)
	}
}

//MARK: - JSONMappable

public protocol JSONMappable: DefaultInitializable, JSONDecodable, JSONEncodeable {
	
	mutating func map(mapper: JSON.Mapper)
}

public extension JSONMappable {
	
	mutating func map(mapper: JSON.Mapper) {}
	
	init(decode json: JSON) throws {
		self.init()
		let mapper = JSON.Mapper(json: json, isCreating: false)
		self.map(mapper: mapper)
		if let error = mapper.json.error { throw error }
		try transform { (pointer, value, index) in
			if mapper.pointerHashValues.contains(pointer.hashValue) { return }
			guard let v = type(of: value).init(mapper.json[index]) else {
					throw JSON.Error.deserilize(from: mapper.json, to: type(of: value))
			}
			type(of: v).code(v, into: pointer)
		}
	}
  
	func encode(mapper: JSON.Mapper) {
		var mutableSelf = self
		mutableSelf.map(mapper: mapper)
		if mapper.json.isError { return }
		do {
			try mutableSelf.transform { (pointer, value, index) in
				if mapper.pointerHashValues.contains(pointer.hashValue) { return }
				let json = value.json
				if let error = json.error { throw error }
				mapper.json[create: index] = json
			}
		} catch let error {
				mapper.json = .error(error)
		}
	}
}

extension JSONMappable {
    
	typealias Operate = (inout Pointer, JSONTransformable, JSON.Index) throws -> ()
    
	func classTransform(by mirror: Mirror, to pointer: inout Pointer,
	                    with offset: inout Int, operate: Operate) throws {
		if let superMirror = mirror.superclassMirror {
			try classTransform(by: superMirror, to: &pointer, with: &offset, operate: operate)
		}
		try strucTransform(by: mirror, to: &pointer, with: &offset, operate: operate)
	}
  
	func strucTransform(by mirror: Mirror, to pointer: inout Pointer,
                      with offset: inout Int, operate: Operate) throws {
		for child in mirror.children {
			guard let value = child.value as? JSONTransformable else {
				throw JSON.Error.unSupportType(type: type(of: child.value))
			}
			
			let size = type(of: value).size
			let offsetToAlignment = type(of: value).offsetToAlignment(offset)
			
			pointer = pointer.advanced(by: offsetToAlignment)
			offset += offsetToAlignment
			
			if let label = child.label {
				try operate(&pointer, value, .key(.key(label)))
			}
			
			pointer = pointer.advanced(by: size)
			offset += size
		}
	}
    
	mutating func transform(operate: Operate) throws {
		let mirror = Mirror(reflecting: self)
		switch mirror.displayStyle {
		case .struct?:
			var pointer = withUnsafePointer(to: &self) { UnsafeRawPointer($0) }
				.bindMemory(to: Int8.self, capacity: MemoryLayout<Self>.stride)
			var offset = 0
			try strucTransform(by: mirror, to: &pointer, with: &offset, operate: operate)
		case .class?:
			let opaquePointer = Unmanaged.passUnretained(self as AnyObject).toOpaque()
			var offset = 8 + MemoryLayout<Int>.size
			let mutablePointer = opaquePointer
				.bindMemory(to: Int8.self, capacity: MemoryLayout<Self>.stride)
			var pointer = Pointer(mutablePointer).advanced(by: offset)
			try classTransform(by: mirror, to: &pointer, with: &offset , operate: operate)
		default:
			throw JSON.Error.unSupportType(type: (type(of: self)))
		}
	}
}

//MARK: - Transform

public protocol Transform {
	
	typealias Func = (JSONTransformable) throws -> JSONTransformable
	
	var jsonObjectType: JSONTransformable.Type { get }
	var objectType: JSONTransformable.Type { get }
	
	var fromJSONFunc: Func? { get }
	var toJSONFunc: Func? { get }
}

//MARK: - JSONMapper

public extension JSON {
	
	final class Mapper {
    
    var json: JSON {
      get {
        defer { getJSON = [] }
        return getJSON.reduce(_json) { $1($0) }
      }
      set {
        guard !newValue.isError else { _json = newValue; return }
        setJSON(with: newValue)(&_json)
      }
    }
		
		private var _json: JSON
		
		let isCreating: Bool
    
    var pointerHashValues: Set<Int> = []
		var getJSON: [(JSON) -> JSON] = []
		var setJSON: [(JSON) -> (inout JSON) -> ()] = []
		
		init(json: JSON, isCreating: Bool) {
			self._json = json
      self.isCreating = isCreating
    }
    
    private func setJSON(with value: JSON) -> (inout JSON) -> () {
      guard !setJSON.isEmpty else { return { $0 = value } }
      let (get, set) = (getJSON.remove(at: 0), setJSON.remove(at: 0))
      return { json in
        var subJSON = get(json)
        self.setJSON(with: value)(&subJSON)
        set(subJSON)(&json)
      }
    }
	}
}

public extension JSON.Mapper {
  
	func ignore<T>(_ any: inout T) {
		pointerHashValues.insert(withUnsafePointer(to: &any, { $0 }).hashValue)
	}
    
	func serialize<T : JSONSerializable>(from any: inout T) {
		ignore(&any)
    json = any.json
	}
    
	func desrialize<T : JSONDeserializable>(to any: inout T) {
		ignore(&any)
		do {
      any = try json.decode()
		} catch let error {
			json = JSON.error(error)
		}
	}
	
	func transform<T : JSONTransformable>(between any: inout T) {
		isCreating ? serialize(from: &any) : desrialize(to: &any)
	}
	
	subscript(noneNull path: JSON.Index...) -> JSON.Mapper {
		get {
      guard isCreating else { getJSON.append { $0[noneNull: path] }; return self }
      getJSON.append { $0[noneNull: path] }
      setJSON.append { value in { (json: inout JSON) in json[noneNull: path] = value } }
			return self
		}
	}
	
	subscript(path: JSON.Index...) -> JSON.Mapper {
		get {
      guard isCreating else { getJSON.append { $0[path] }; return self }
      getJSON.append { $0[create: path] }
      setJSON.append { value in { (json: inout JSON) in json[create: path] = value } }
			return self
		}
	}
	
	subscript(index: JSON.Index) -> JSON.Mapper {
		get {
      guard isCreating else { getJSON.append { $0[index] }; return self }
      getJSON.append { $0[create: index] }
      setJSON.append { value in { (json: inout JSON) in json[create: index] = value } }
			return self
		}
	}
	
	subscript(transform: Transform) -> JSON.Mapper {
		get {
      getJSON.append { $0[transform] }
      guard isCreating else { return self }
      setJSON.append { value in { (json: inout JSON) in json[transform] = value } }
			return self
		}
	}
}

//MARK: - <>

postfix operator <

public postfix func <<T : JSONDeserializable>(json: JSON) throws -> T {
  return try json.decode()
}

infix operator <>

public func <><T : JSONTransformable>(lhs: inout T, rhs: JSON.Mapper) {
	rhs.transform(between: &lhs)
}

infix operator ><

public func ><<T : JSONTransformable>(lhs: inout T, rhs: JSON.Mapper) {
	rhs.ignore(&lhs)
}

//MARK: - >>

public func >><T: JSONSerializable>(lhs: inout T, rhs: JSON.Mapper) {
	rhs.serialize(from: &lhs)
}

//MARK: - <<

public func <<<T : JSONDeserializable>(lhs: inout T, rhs: JSON.Mapper) {
	rhs.desrialize(to: &lhs)
}

public func <<<T : JSONSerializable>(lhs: JSON.Mapper, rhs: T) {
	if lhs.isCreating { lhs.json = rhs.json }
}

public func <<<T : JSONDeserializable>(lhs: JSON, rhs: JSON.Index) -> T? {
	return try? lhs[rhs].decode()
}
