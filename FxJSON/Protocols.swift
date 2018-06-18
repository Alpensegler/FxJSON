//
//  Protocols.swift
//  FxJSON
//
//  Created by Frain on 7/5/16.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016~2017 Frain
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

//MARK: - JSONEncodable

public protocol JSONEncodable {
  
  var json: JSON { get }
  
  func encode(wrapper: JSON.Wrapper)
  
  static func specificOptions() -> [String: SpecificOption]
}

public extension JSONEncodable {
  
  var json: JSON {
    return JSON(operate: encode)
  }
  
  func encode(wrapper: JSON.Wrapper) {
    let type = self is DefaultInitable ? Mirror(reflecting: self).subjectType : Self.self
    let info = Metadata(type: type)
    var mutableSelf = self
    let selfPointer = info.getPointer(of: &mutableSelf)
    for (name, type, offset) in info.properties {
      let index = name
      var setJSON = { (json: inout JSON, value: JSON) in json[create: index] = value }
      if let options = Self.specificOptions()[name] {
        if options.contains(.ignore) { continue }
        if options.contains(.ignoreIfNull) { setJSON = { $0[ignoreIfNull: [index]] = $1 } }
//        if let idx = options.index { index = idx }
        let set = setJSON
        if let transform = options.transform {
          setJSON = { json, value in
            var subJSON = json[create: index]
            subJSON[transform] = value
            set(&json, subJSON)
          }
        }
      }
      guard let serializable = type as? JSONEncodable.Type else {
        wrapper.json = .error(JSON.Error.notConfirmTo(protocol: JSONEncodable.self, actual: type))
        return
      }
      let value = serializable.fetchValue(from: selfPointer.advanced(by: offset))
      setJSON(&wrapper.json, value.json)
    }
  }
  
  static func specificOptions() -> [String: SpecificOption] {
    return [:]
  }
  
  func jsonData(withOptions opt: JSONSerialization.WritingOptions = []) throws -> Data {
    return try wrap(json).jsonData(withOptions: opt)
  }
  
  func jsonString(withOptions opt: JSONSerialization.WritingOptions = [],
                  encoding ecd: String.Encoding = String.Encoding.utf8) throws -> String {
    return try wrap(json).jsonString(withOptions: opt, encoding: ecd)
  }
}

public extension JSONEncodable where Self: RawRepresentable, Self.RawValue: JSONEncodable {
  
  func encode(wrapper: JSON.Wrapper) {
    wrapper.json = self.rawValue.json
  }
}

extension JSONEncodable {
  
  static func fetchValue(from pointer: UnsafeRawPointer) -> JSONEncodable {
    return pointer.load(as: Self.self)
  }
}

//MARK: - JSONDecodable

public protocol JSONDecodable {
  
  init?(_ json: JSON)
  
  init(decode json: JSON) throws
  
  static func specificOptions() -> [String: SpecificOption]
}

public extension JSONDecodable {
  
  init?(_ json: JSON) {
    guard let value = try? Self.init(decode: json) else { return nil }
    self = value
  }
  
  init(decode json: JSON) throws {
    let object = UnsafeMutablePointer<Self>.allocate(capacity: 1)
    defer { object.deallocate() }
    let rawObject = UnsafeMutableRawPointer(object)
    let info = Metadata(type: Self.self)
    let options = Self.specificOptions()
    guard info.kind == .struct else {
      throw JSON.Error.other(description: "Only struct can implement JSONDecodable by default")
    }
    try info.properties.forEach {
      let value = try Self.fetchValue(property: $0, json: json, from: options)
      type(of: value).initialize(value, into: rawObject.advanced(by: $0.offset))
    }
    self = rawObject.load(fromByteOffset: 0, as: Self.self)
  }
  
  static func specificOptions() -> [String: SpecificOption] {
    return [:]
  }
  
  init?(any: Any) {
    self.init(JSON(any: any))
  }
  
  init(jsonData: Data?, options: JSONSerialization.ReadingOptions = []) throws {
    let json = JSON.init(jsonData: jsonData, options: options)
    self = try Self.init(decode: json)
  }
  
  init(jsonString: String?, options: JSONSerialization.ReadingOptions = []) throws {
    let json = JSON.init(jsonString: jsonString, options: options)
    self = try Self.init(decode: json)
  }
}

extension JSONDecodable {
  
  static func mismatchError(json: JSON) -> Error {
    return wrap(json).error ?? JSON.Error.typeMismatch(expected: Self.self, actual: wrap(json).type)
  }
}

public extension JSONDecodable where Self: DefaultInitable {
  
  init(decode json: JSON) throws {
    self.init()
    let type = Mirror(reflecting: self).subjectType as! JSONDecodable.Type
    let info = Metadata(type: type)
    let options = type.specificOptions()
    guard info.kind != .enum else {
      throw JSON.Error.other(description: "enum can not implement JSONDecodable by default")
    }
    let selfPointer = info.getPointer(of: &self)
    try info.properties.forEach {
      let value = try Self.fetchValue(property: $0, json: json, from: options)
      Swift.type(of: value).update(value, into: selfPointer.advanced(by: $0.offset))
    }
  }
}

public extension JSONDecodable
where Self: RawRepresentable, Self.RawValue: JSONDecodable {
  
  init(decode json: JSON) throws {
    guard let value = Self(rawValue: try RawValue(decode: json)) else {
      throw JSON.Error.other(description: "RawValue init error, json is \(json)")
    }
    self = value
  }
}

extension JSONDecodable {
  
  static func fetchValue(property: Metadata.Property, json: JSON, from options: [String: SpecificOption]) throws -> JSONDecodable {
    let index = property.key
    var getJSON = { json[index] }
    if let options = options[property.key] {
//      if let idx = options.index { index = idx }
//      if let idx = options.alertIndex, wrap(json[index]).isError { index = idx }
      if let transform = options.transform { getJSON = { json[index][transform] } }
      if let value = options.defaultValue {
        guard type(of: value) == property.type, let deserializable = property.type as? JSONDecodable.Type else {
          throw JSON.Error.notConfirmTo(protocol: JSONDecodable.self, actual: type(of: value))
        }
        return deserializable.init(getJSON()) ?? (value as! JSONDecodable)
      }
      if options.contains(.nonNil), let initable = property.type as? (JSONDecodable & DefaultInitable).Type {
        return initable.init(nonNil: getJSON())
      }
    }
    guard let deserializable = property.type as? JSONDecodable.Type else {
      throw JSON.Error.notConfirmTo(protocol: JSONDecodable.self, actual: property.type)
    }
    return try deserializable.init(decode: getJSON())
  }
  
  static func initialize(_ value: JSONDecodable, into pointer: UnsafeMutableRawPointer) {
    let bind = pointer.bindMemory(to: Self.self, capacity: 1)
    bind.initialize(to: value as! Self)
  }
  
  static func update(_ value: JSONDecodable, into pointer: UnsafeMutableRawPointer) {
    let bind = pointer.bindMemory(to: Self.self, capacity: 1)
    bind.pointee = value as! Self
  }
}

//MARK: - DefaultInitable

public protocol DefaultInitable {
  
  init()
}

public extension JSONDecodable where Self: DefaultInitable {
  
  init(nonNil json: JSON) {
    self = Self.init(json) ?? Self.init()
  }
}

//MARK: - JSONConvertable

public protocol JSONConvertable: JSONDecodable {
    
  static func convert(from json: JSON) -> Self?
}

public extension JSONConvertable {
  
  init?(_ json: JSON) {
    guard let v = Self.convert(from: json) else { return nil }
    self = v
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
  
  typealias Func = (JSONCodable) throws -> JSONCodable
  
  var jsonObjectType: JSONCodable.Type { get }
  var objectType: JSONCodable.Type { get }
  
  var fromJSONFunc: Func? { get }
  var toJSONFunc: Func? { get }
}

//MARK: - SpecificOption

public struct SpecificOption: OptionSet {
  
  public let rawValue: Int
  
  let index: JSON.KeyPath?
  let alertIndex: JSON.KeyPath?
  let transform: Transform?
  let defaultValue: Any?
  
  init(rawValue: Int, index: JSON.KeyPath? = nil, alertIndex: JSON.KeyPath? = nil,
       transform: Transform? = nil, defaultValue: Any? = nil) {
    self.rawValue = rawValue
    self.index = index
    self.alertIndex = alertIndex
    self.transform = transform
    self.defaultValue = defaultValue
  }
  
  public static let index = { SpecificOption(rawValue: 1 << 0, index: $0) }
  public static let alertIndex = { SpecificOption(rawValue: 1 << 1, alertIndex: $0) }
  public static let transform = { SpecificOption(rawValue: 1 << 2, transform: $0) }
  public static let defaultValue = { SpecificOption(rawValue: 1 << 3, defaultValue: $0) }
  public static let nonNil = SpecificOption(rawValue: 1 << 4)
  public static let ignore = SpecificOption(rawValue: 1 << 5)
  public static let ignoreIfNull = SpecificOption(rawValue: 1 << 6)
  
  public init(rawValue: Int) {
    self.init(rawValue: rawValue, index: nil, alertIndex: nil, transform: nil, defaultValue: nil)
  }
  
  public mutating func formUnion(_ other: SpecificOption) {
    self = SpecificOption(
      rawValue: rawValue | other.rawValue,
      index: index ?? other.index,
      alertIndex: alertIndex ?? other.alertIndex,
      transform: transform ?? other.transform,
      defaultValue: defaultValue ?? other.defaultValue
    )
  }
  
  @discardableResult
  public mutating func insert(_ newMember: SpecificOption)
    -> (inserted: Bool, memberAfterInsert: SpecificOption) {
    formUnion(newMember)
    return (true, self)
  }
}

//MARK: - operator

postfix operator <

public postfix func <<T: JSONDecodable>(json: JSON) throws -> T {
  return try wrap(json).decode()
}

public func <<<T: JSONEncodable>(lhs: JSON.Wrapper, rhs: T) {
  lhs.set(json: rhs.json)
}

public func <<<T: JSONDecodable>(lhs: JSON, rhs: JSONKeyConvertible) -> T? {
  return try? wrap(lhs[rhs]).decode()
}

//MARK: - Metadata

protocol NominalType {
  
  init(pointer: UnsafePointer<Int>)
  var pointer: UnsafePointer<Int> { get set }
  var nominalTypeDescriptorOffsetLocation: Int { get }
  var properties: [Metadata.Property] { get }
}

fileprivate extension UnsafePointer {
  init<T>(_ pointer: UnsafePointer<T>, offset: Int? = nil) {
    var rawPointer = UnsafeRawPointer(pointer)
    if let offset = offset { rawPointer = rawPointer.advanced(by: offset) }
    self = rawPointer.assumingMemoryBound(to: Pointee.self)
  }
}

struct Metadata {
  
  typealias Property = (key: String, type: Any.Type, offset: Int)
  
  struct Class: NominalType {
    
    typealias Meta = (kind: Int, superClass: Any.Type?)
    
    var pointer: UnsafePointer<Int>
    var nominalTypeDescriptorOffsetLocation: Int {
      return MemoryLayout<Int>.size == MemoryLayout<Int64>.size ? 8 : 11
    }
    
    var properties: [Property] {
      let metaClassPointer = pointer.withMemoryRebound(to: Meta.self, capacity: 1) { $0 }
      guard let superClass = metaClassPointer.pointee.superClass else { return [] }
      let superClassMetaData = Metadata(type: superClass)
      return superClassMetaData.properties + NominalTypeDescriptor(nominalType: self).properties()
    }
  }
  
  struct Struct: NominalType {
    var pointer: UnsafePointer<Int>
    var nominalTypeDescriptorOffsetLocation: Int {
      return 1
    }
    
    var properties: [Property] {
      return NominalTypeDescriptor(nominalType: self).properties()
    }
  }
  
  enum Kind: Int {
    case `class`
    case `struct`
    case `enum`
    case objCClassWrapper = 14
    
    init(_ kind: Int) {
      self = Kind(rawValue: kind) ?? .class
    }
    
    var nominalType: NominalType.Type? {
      switch self {
      case .class: return Class.self
      case .struct: return Struct.self
      default: return nil
      }
    }
  }
  
  static var propertyCache: [UnsafePointer<Int>: [Property]] = [:]
  
  let kind: Kind
  let properties: [Property]
  
  init(type: Any.Type) {
    let typePointer = unsafeBitCast(type, to: UnsafePointer<Int>.self)
    kind = Kind(typePointer.pointee)
    if let properties = Metadata.propertyCache[typePointer] {
      self.properties = properties
    } else if let properties = kind.nominalType?.init(pointer: typePointer).properties {
      Metadata.propertyCache[typePointer] = properties
      self.properties = properties
    } else {
      self.properties = []
    }
  }
  
  func getPointer<T>(of any: inout T) -> UnsafeMutableRawPointer {
    switch kind {
    case .struct:
      return UnsafeMutableRawPointer(mutating: withUnsafePointer(to: &any, { $0 }))
    default:
      return Unmanaged.passUnretained(any as AnyObject).toOpaque()
    }
  }
  
  struct NominalTypeDescriptor {
    
    struct Meta {
      let mangledName: Int32
      let numberOfFields: Int32
      let fieldOffsetVector: Int32
      let fieldNames: Int32
      let fieldTypesAccessor: Int32
    }
    
    typealias FieldsTypeAccessor = @convention(c) (UnsafePointer<Int>) -> UnsafePointer<UnsafePointer<Int>>
    
    let typePointer: UnsafePointer<Int>
    let numberOfFields: Int
    let fieldOffsetVector: Int
    let fieldTypesAccessor: FieldsTypeAccessor
    let fieldNamePointer: UnsafePointer<CChar>
    
    init(nominalType: NominalType) {
      let base = nominalType.pointer.advanced(by: nominalType.nominalTypeDescriptorOffsetLocation)
      typePointer = nominalType.pointer
      let pointer = UnsafePointer<NominalTypeDescriptor.Meta>(base, offset: base.pointee)
      numberOfFields = Int(pointer.pointee.numberOfFields)
      fieldOffsetVector = Int(pointer.pointee.fieldOffsetVector)
      let offset = Int(pointer.pointee.fieldTypesAccessor)
      let int32Pointer = UnsafePointer<Int32>(pointer)
      let offsetPointer = UnsafePointer<Int>(int32Pointer.advanced(by: 4), offset: Int(offset))
      fieldTypesAccessor = unsafeBitCast(offsetPointer, to: FieldsTypeAccessor.self)
      fieldNamePointer = UnsafePointer<CChar>(int32Pointer.advanced(by: 3), offset: Int(pointer.pointee.fieldNames))
    }
    
    func properties() -> [Property] {
      var fieldNamePointer = self.fieldNamePointer
      return (0..<numberOfFields).compactMap { i in
        guard let key = String(validatingUTF8: fieldNamePointer) else { return nil }
        while fieldNamePointer.pointee != 0 {
          fieldNamePointer = fieldNamePointer.advanced(by: 1)
        }
        fieldNamePointer = fieldNamePointer.advanced(by: 1)
        let type = unsafeBitCast(fieldTypesAccessor(typePointer).advanced(by: i).pointee, to: Any.Type.self)
        let offset = UnsafePointer<Int>(typePointer)[fieldOffsetVector + i]
        return (key: key, type: type, offset: offset)
      }
    }
  }
}
