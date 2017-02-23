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

//MARK: - JSONSerializable

public protocol JSONSerializable {
  
  var json: JSON { get }
}

public extension JSONSerializable {
  
  func jsonData(withOptions opt: JSONSerialization.WritingOptions = []) throws -> Data {
    return try json.jsonData(withOptions: opt)
  }
  
  func jsonString(withOptions opt: JSONSerialization.WritingOptions = [],
                  encoding ecd: String.Encoding = String.Encoding.utf8) throws -> String {
    return try json.jsonString(withOptions: opt, encoding: ecd)
  }
}

extension JSONSerializable {
  
  static func fetchValue(from pointer: UnsafeRawPointer) -> JSONSerializable {
    return pointer.load(as: Self.self)
  }
}

//MARK: - JSONDeserializable

public protocol JSONDeserializable {
  
  init?(_ json: JSON)
  
  init(decode json: JSON) throws
}

public extension JSONDeserializable {
  
  init(jsonData: Data?, options: JSONSerialization.ReadingOptions = []) throws {
    let json = JSON.init(jsonData: jsonData, options: options)
    self = try Self.init(decode: json)
  }
    
  init(jsonString: String?, options: JSONSerialization.ReadingOptions = []) throws {
    let json = JSON.init(jsonString: jsonString, options: options)
    self = try Self.init(decode: json)
  }
  
  init(decode json: JSON) throws {
    guard let value = Self.init(json) else {
      throw json.error ?? JSON.Error.deserilize(from: json, to: Self.self)
    }
    self = value
  }
}

extension JSONDeserializable {
  
  static func initialize(_ value: JSONDeserializable, into pointer: UnsafeMutableRawPointer) {
    let bind = pointer.bindMemory(to: Self.self, capacity: 1)
    bind.initialize(to: value as! Self)
  }
  
  static func update(_ value: JSONDeserializable, into pointer: UnsafeMutableRawPointer) {
    let bind = pointer.bindMemory(to: Self.self, capacity: 1)
    bind.pointee = value as! Self
  }
}

//MARK: - DefaultInitable

public protocol DefaultInitable {
  
  init()
}

public extension JSONDeserializable where Self: DefaultInitable {
  
  init(nonNil json: JSON) {
    self = Self.init(json) ?? Self.init()
  }
}

//MARK: - JSONTransformable

public typealias JSONTransformable = JSONDeserializable & JSONSerializable

//MARK: - JSONConvertable

public protocol JSONConvertable: JSONDeserializable {
    
  static func convert(from json: JSON) -> Self?
}

public extension JSONConvertable {
  
  init?(_ json: JSON) {
    guard let v = Self.convert(from: json) else { return nil }
    self = v
  }
}

//MARK: - JSONDecodable

public protocol JSONDecodable: JSONDeserializable {
  
  static func specificOptions() -> [String: SpecificOption]
}

public extension JSONDecodable {
  
  static func specificOptions() -> [String: SpecificOption] {
    return [:]
  }
  
  init(decode json: JSON) throws {
    let object = UnsafeMutablePointer<Self>.allocate(capacity: 1)
    defer { object.deallocate(capacity: 1) }
    let rawObject = UnsafeMutableRawPointer(object)
    let info = Metadata(type: Self.self)
    let options = Self.specificOptions()
    precondition(info.kind == .struct, "Only struct can implement JSONDecodable by default")
    try info.properties.forEach {
      let value = try Self.fetchValue(property: $0, json: json, from: options)
      type(of: value).initialize(value, into: rawObject.advanced(by: $0.offset))
    }
    self = rawObject.load(fromByteOffset: 0, as: Self.self)
  }
  
  init?(_ json: JSON) {
    guard let value = try? Self.init(decode: json) else { return nil }
    self = value
  }
}

public extension JSONDecodable where Self: DefaultInitable {
  
  init(decode json: JSON) throws {
    self.init()
    let type = Mirror(reflecting: self).subjectType as! JSONDecodable.Type
    let info = Metadata(type: type)
    let options = type.specificOptions()
    precondition(info.kind != .enum, "Enum can only adopt JSONDecodable to implement by default")
    let selfPointer = info.getPointer(of: &self)
    try info.properties.forEach {
      let value = try Self.fetchValue(property: $0, json: json, from: options)
      type(of: value).update(value, into: selfPointer.advanced(by: $0.offset))
    }
  }
}

public extension JSONDecodable
where Self: RawRepresentable, Self.RawValue: JSONDeserializable {
  
  init(decode json: JSON) throws {
    guard let value = RawValue(json).flatMap(Self.init) else {
      throw JSON.Error.deserilize(from: json, to: Self.self)
    }
    self = value
  }
}

extension JSONDecodable {
  
  static func fetchValue(property: Metadata.Property, json: JSON, from options: [String: SpecificOption]) throws -> JSONDeserializable {
    var index = JSON.Index(stringLiteral: property.name)
    var getJSON = { json[index] }
    if let options = options[property.name] {
      if let idx = options.index { index = idx }
      if let transform = options.transform { getJSON = { json[index][transform] } }
      if let value = options.defaultValue {
        guard type(of: value) == property.type, let deserializable = property.type as? JSONDeserializable.Type else {
          throw JSON.Error.unSupportType(type: type(of: value))
        }
        return deserializable.init(getJSON()) ?? (value as! JSONDeserializable)
      }
      if options.contains(.nonNil), let initable = property.type as? (JSONDeserializable & DefaultInitable).Type {
        return initable.init(nonNil: getJSON())
      }
    }
    guard let deserializable = property.type as? JSONDeserializable.Type else {
      throw JSON.Error.unSupportType(type: property.type)
    }
    return try deserializable.init(decode: getJSON())
  }
}

//MARK: - JSONEncodable

public protocol JSONEncodable: JSONSerializable {
  
  func encode(mapper: JSON.Mapper)
  
  static func specificOptions() -> [String: SpecificOption]
}

public extension JSONEncodable {
  
  func encode(mapper: JSON.Mapper) {
    let type = self is DefaultInitable ? Mirror(reflecting: self).subjectType : Self.self
    let info = Metadata(type: type)
    var mutableSelf = self
    let selfPointer = info.getPointer(of: &mutableSelf)
    for (name, type, offset) in info.properties {
      var index = JSON.Index(stringLiteral: name)
      var setJSON = { (json: inout JSON, value: JSON) in json[create: index] = value }
      if let options = Self.specificOptions()[name] {
        if options.contains(.ignore) { continue }
        if options.contains(.ignoreIfNull) { setJSON = { $0[ignoreIfNull: [index]] = $1 } }
        if let idx = options.index { index = idx }
        let set = setJSON
        if let transform = options.transform {
          setJSON = { json, value in
            var subJSON = json[create: index]
            subJSON[transform] = value
            set(&json, subJSON)
          }
        }
      }
      guard let serializable = type as? JSONSerializable.Type else {
        mapper.json = .error(JSON.Error.unSupportType(type: type))
        return
      }
      let value = serializable.fetchValue(from: selfPointer.advanced(by: offset))
      setJSON(&mapper.json, value.json)
    }
  }
  
  static func specificOptions() -> [String: SpecificOption] {
    return [:]
  }
  
  var json: JSON {
    return JSON.init(operate: encode)
  }
}

public extension JSONEncodable where Self: RawRepresentable, Self.RawValue: JSONSerializable {
  
  func encode(mapper: JSON.Mapper) {
    mapper.json = self.rawValue.json
  }
}

//MARK: - JSONCodable

public typealias JSONCodable = JSONEncodable & JSONDecodable

public extension JSONDecodable where Self: JSONEncodable {
  
  static func specificOptions() -> [String: SpecificOption] {
    return [:]
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

//MARK: - SpecificOption

public struct SpecificOption: OptionSet {
  
  public let rawValue: Int
  
  let index: JSON.Index?
  let transform: Transform?
  let defaultValue: Any?
  
  init(rawValue: Int, index: JSON.Index? = nil, transform: Transform? = nil, defaultValue: Any? = nil) {
    self.rawValue = rawValue
    self.index = index
    self.transform = transform
    self.defaultValue = defaultValue
  }
  
  public static let index = { SpecificOption(rawValue: 1 << 0, index: $0) }
  public static let transform = { SpecificOption(rawValue: 1 << 1, transform: $0) }
  public static let defaultValue = { SpecificOption(rawValue: 1 << 2, defaultValue: $0) }
  public static let nonNil = SpecificOption(rawValue: 1 << 3)
  public static let ignore = SpecificOption(rawValue: 1 << 4)
  public static let ignoreIfNull = SpecificOption(rawValue: 1 << 5)
  
  public init(rawValue: Int) {
    self.init(rawValue: rawValue, index: nil, transform: nil, defaultValue: nil)
  }
  
  public mutating func formUnion(_ other: SpecificOption) {
    self = SpecificOption(
      rawValue: rawValue | other.rawValue,
      index: index ?? other.index,
      transform: transform ?? other.transform,
      defaultValue: defaultValue ?? other.defaultValue
    )
  }
}

extension SpecificOption: ExpressibleByStringLiteral {
  
  public init(stringLiteral value: String) {
    self = SpecificOption.index(.key(.key(value)))
  }
  
  public init(unicodeScalarLiteral value: String) {
    self = SpecificOption.index(.key(.key(value)))
  }
  
  public init(extendedGraphemeClusterLiteral value: String) {
    self = SpecificOption.index(.key(.key(value)))
  }
}


//MARK: - JSONMapper

public extension JSON {
  
  final class Mapper {
    
    var json: JSON
    
    var getJSON: [(JSON) -> JSON] = []
    var setJSON: [(JSON) -> (inout JSON) -> ()] = []
    
    init(json: JSON) {
      self.json = json
    }
    
    func set(json: JSON) {
      setJSON(with: json)(&self.json)
    }
    
    private func setJSON(with value: JSON) -> (inout JSON) -> () {
      guard !setJSON.isEmpty else { return { $0 = value } }
      let (get, set) = (getJSON.remove(at: 0), setJSON.remove(at: 0))
      return { json in
        var subJSON = get(json)
        self.setJSON(with: value)(&subJSON)
        if subJSON.isError { json = subJSON; return }
        set(subJSON)(&json)
      }
    }
  }
}

public extension JSON.Mapper {
  
  subscript(ignoreIfNull path: JSON.Index...) -> JSON.Mapper {
    get {
      getJSON.append { $0[ignoreIfNull: path] }
      setJSON.append { value in { (json: inout JSON) in json[ignoreIfNull: path] = value } }
      return self
    }
  }
  
  subscript(path: JSON.Index...) -> JSON.Mapper {
    get {
      getJSON.append { $0[create: path] }
      setJSON.append { value in { (json: inout JSON) in json[create: path] = value } }
      return self
    }
  }
  
  subscript(index: JSON.Index) -> JSON.Mapper {
    get {
      getJSON.append { $0[create: index] }
      setJSON.append { value in { (json: inout JSON) in json[create: index] = value } }
      return self
    }
  }
  
  subscript(transform: Transform) -> JSON.Mapper {
    get {
      getJSON.append { $0[transform] }
      setJSON.append { value in { (json: inout JSON) in json[transform] = value } }
      return self
    }
  }
}

//MARK: - operator

postfix operator <

public postfix func <<T: JSONDeserializable>(json: JSON) throws -> T {
  return try json.decode()
}

public func <<<T: JSONSerializable>(lhs: JSON.Mapper, rhs: T) {
  lhs.set(json: rhs.json)
}

public func <<<T: JSONDeserializable>(lhs: JSON, rhs: JSON.Index) -> T? {
  return try? lhs[rhs].decode()
}

//MARK: - Metadata

public struct Metadata {
  
  typealias Structure = (kind: Int, offset: Int)
  
  typealias Property = (name: String, type: Any.Type, offset: Int)
  
  struct NominalTypeDescriptor {
    var name: Int32
    var numberOfFields: Int32
    var FieldOffsetVectorOffset: Int32
    var fieldNames: Int32
    var getFieldTypes: Int32
  }
  
  struct Class {
    var isa: UnsafePointer<Class>
    var superIsa: UnsafePointer<Class>
    var data: (Int, Int, Int, Int32, Int32, Int32, Int16, Int16, Int32, Int32)
    var description: Int
  }
  
  enum Kind {
    case `struct`
    case `class`
    case `enum`
    case objCClassWrapper
  }
  
  static var table: [UnsafePointer<Structure>: Metadata] = [:]
  
  let kind: Kind
  let properties: [Property]
  
  init(kind: Kind, properties: [Property] = []) {
    self.kind = kind
    self.properties = properties
  }
  
  init(type: Any.Type) {
    let typePointer = unsafeBitCast(type, to: UnsafePointer<Structure>.self)
    if let value = Metadata.table[typePointer] {
      self.init(kind: value.kind, properties: value.properties)
      return
    }
    switch typePointer.pointee.kind {
    case 1:
      self.init(structTypePointer: typePointer)
    case 2:
      self.init(kind: .enum)
    case 14:
      self.init(kind: .objCClassWrapper)
    default:
      self.init(classTypePointer: typePointer)
    }
    Metadata.table[typePointer] = self
  }
  
  init(structTypePointer: UnsafePointer<Structure>) {
    let intPointer = unsafeBitCast(structTypePointer, to: UnsafePointer<Int>.self)
    let nominalTypeBase = intPointer.advanced(by: 1)
    let int8Type = unsafeBitCast(nominalTypeBase, to: UnsafePointer<Int8>.self)
    let nominalTypePointer = int8Type.advanced(by: structTypePointer.pointee.offset)
    let nominalType = unsafeBitCast(nominalTypePointer, to: UnsafePointer<NominalTypeDescriptor>.self)
    kind = .struct
    properties = Metadata.getProperties(intPointer: intPointer, nominalType: nominalType, isClass: false)
  }
  
  init(classTypePointer: UnsafePointer<Structure>) {
    let classTypePointer = unsafeBitCast(classTypePointer, to: UnsafePointer<Class>.self)
    kind = .class
    properties = Metadata.getProperties(classTypePointer: classTypePointer)
  }
  
  func getPointer<T>(of any: inout T) -> UnsafeMutableRawPointer {
    switch kind {
    case .struct:
      return UnsafeMutableRawPointer(mutating: withUnsafePointer(to: &any, { $0 }))
    default:
      return Unmanaged.passUnretained(any as AnyObject).toOpaque()
    }
  }
  
  static func getProperties(classTypePointer: UnsafePointer<Class>) -> [Property] {
    let intPointer = unsafeBitCast(classTypePointer, to: UnsafePointer<Int>.self)
    let typePointee = classTypePointer.pointee
    let superPointee = typePointee.superIsa
    if unsafeBitCast(typePointee.isa, to: Int.self) == 14 || unsafeBitCast(superPointee, to: Int.self) == 0 {
      return []
    }
    let properties = getProperties(classTypePointer: superPointee)
    let offset = (MemoryLayout<Int>.size == MemoryLayout<Int64>.size) ? 8 : 11
    let nominalTypeInt = intPointer.advanced(by: offset)
    let nominalTypeint8 = unsafeBitCast(nominalTypeInt, to: UnsafePointer<Int8>.self)
    let des = nominalTypeint8.advanced(by: typePointee.description)
    let nominalType = unsafeBitCast(des, to: UnsafePointer<NominalTypeDescriptor>.self)
    return properties + getProperties(intPointer: intPointer, nominalType: nominalType, isClass: true)
  }
  
  static func getProperties(intPointer: UnsafePointer<Int>, nominalType: UnsafePointer<NominalTypeDescriptor>, isClass: Bool) -> [Property] {
    let numberOfField = Int(nominalType.pointee.numberOfFields)
    let int32NominalType = unsafeBitCast(nominalType, to: UnsafePointer<Int32>.self)
    let fieldBase = int32NominalType.advanced(by: isClass ? 3 : Int(nominalType.pointee.FieldOffsetVectorOffset))
    let int8FieldBasePointer = unsafeBitCast(fieldBase, to: UnsafePointer<Int8>.self)
    var fieldNamePointer = int8FieldBasePointer.advanced(by: Int(nominalType.pointee.fieldNames))
    let int32NominalFunc = unsafeBitCast(nominalType, to: UnsafePointer<Int32>.self).advanced(by: 4)
    let nominalFunc = unsafeBitCast(int32NominalFunc, to: UnsafePointer<Int8>.self).advanced(by: Int(nominalType.pointee.getFieldTypes))
    let offsetPointer = intPointer.advanced(by: Int(nominalType.pointee.FieldOffsetVectorOffset))
    typealias FieldsTypeAccessor = @convention(c) (UnsafePointer<Int>) -> UnsafePointer<UnsafePointer<Int>>
    let funcPointer = unsafeBitCast(nominalFunc, to: FieldsTypeAccessor.self)
    let funcBase = funcPointer(unsafeBitCast(nominalFunc, to: UnsafePointer<Int>.self))
    return (0..<numberOfField).flatMap { i in
      guard let name = String(validatingUTF8: fieldNamePointer) else { return nil }
      while fieldNamePointer.pointee != 0 {
        fieldNamePointer = fieldNamePointer.advanced(by: 1)
      }
      fieldNamePointer = fieldNamePointer.advanced(by: 1)
      let offset = offsetPointer.advanced(by: i)
      let typeFetcher = funcBase.advanced(by: i).pointee
      let type = unsafeBitCast(typeFetcher, to: Any.Type.self)
      return (name: name, type: type, offset: offset.pointee)
    }
  }
}
