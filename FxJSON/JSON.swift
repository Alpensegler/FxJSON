//
//  JSON.swift
//  FxJSON
//
//  Created by Frain on 7/2/16.
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

//MARK: - JSON

@dynamicMemberLookup
public enum JSON {
  
  public enum Number {
    case double(Double)
    case int(Int)
    
    var object: Any {
      switch self {
      case .double(let any as Any),
           .int(let any as Any):
        return any
      }
    }
  }
  
  public struct Null { }
  
  case object([String: Any])
  case array([Any])
  case string(String)
  case number(Number)
  case bool(Bool)
  case error(Swift.Error)
  case null
}

//MARK: - Init

public extension JSON {
  
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
      } else if let intValue = num as? Int {
        self = .number(.int(intValue))
      } else {
        self = .number(.double(num.doubleValue))
      }
    case let err as Swift.Error:
      self = .error(err)
    default:
      self = .null
    }
  }
}

//MARK: - Error handling

public extension JSON {
    
  enum Error: Swift.Error, CustomStringConvertible {
    
    case initalize(error: Swift.Error)
    case typeMismatch(expected: Any.Type, actual: Any.Type)
    case notConfirmTo(protocol: Any.Type, actual: Any.Type)
    case encodeToJSON(wrongObject: Any)
    case notExist(dict: [String: Any], key: String)
    case wrongType(subscript: JSON, key: JSONKeyConvertible)
    case outOfBounds(arr: [Any], index: Int)
    case formatter(format: String, value: String)
    case customTransfrom(source: Any)
    case other(description: String)
    
    public var description: String {
      switch self {
      case .initalize(let error):
        return "Initalize error, \(error))"
      case let .typeMismatch(expected, actual):
        return "TypeMismatch, expected \(expected), got \(actual))"
      case let .notConfirmTo(`protocol`, actual):
        return "\(actual) does not confirm to \(`protocol`)"
      case .encodeToJSON(wrongObject: let any):
        return "Error when encoding to JSON: \(any)"
      case .notExist(dict: let dict, key: let key):
        return "Key: \"\(key)\" not exist, dict is: \(dict)"
      case .wrongType(subscript: let json, key: let key):
        return "Cannot subscrpit key: \(key) to \(wrap(json).debugDescription)"
      case .outOfBounds(arr: let arr, index: let index):
        return "Subscript \(index) to \(arr) is out of bounds"
      case .formatter(format: let format, value: let value):
        return "Cannot phrase \(value) with \(format)"
      case .customTransfrom(source: let source):
        return "CustomTransfrom error, source: \(source)"
      case .other(description: let description):
        return description
      }
    }
  }
}

// MARK: - ExpressibleByLiteral

extension JSON: ExpressibleByDictionaryLiteral {
  
  public init(dictionaryLiteral elements: (String, JSONEncodable)...) {
    var dict = [String: Any](minimumCapacity: elements.count)
    for element in elements { dict[element.0] = wrap(element.1.json).object }
    self = .object(dict)
  }
}

extension JSON: ExpressibleByArrayLiteral {
  
  public init(arrayLiteral elements: JSONEncodable...) {
    self = .array(elements.map { wrap($0.json).object })
  }
}

extension JSON: ExpressibleByStringLiteral {
  
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

extension JSON: ExpressibleByIntegerLiteral {
  
  public init(integerLiteral value: IntegerLiteralType) {
    self = .number(.int(value))
  }
}

extension JSON: ExpressibleByFloatLiteral {
  
  public init(floatLiteral value: FloatLiteralType) {
    self = .number(.double(value))
  }
}

extension JSON: ExpressibleByBooleanLiteral {
  
  public init(booleanLiteral value: BooleanLiteralType) {
    self = .bool(value)
  }
}

extension JSON: ExpressibleByNilLiteral {
  
  public init(nilLiteral: ()) {
    self.init()
  }
}

//MARK: - convert from jsonData and jsonString

public extension JSON {
    
  init(jsonData: Data?, options: JSONSerialization.ReadingOptions = []) {
    guard let data = jsonData else { self.init(); return }
    do {
      let object = try JSONSerialization.jsonObject(with: data, options: options)
      self.init(any: object)
    } catch {
      self = .error(JSON.Error.initalize(error: error))
    }
  }
  
  init(jsonString: String?, options: JSONSerialization.ReadingOptions = []) {
    self.init(jsonData: jsonString?.data(using: String.Encoding.utf8), options: options)
  }
}

//MARK: - Equatable

extension JSON: Equatable {
  public static func ==(lhs: JSON, rhs: JSON) -> Bool {
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
}

extension JSON.Number: Equatable { }

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
      if case let (key, value?) = f(key, value) {
        dict[key] = value
      }
    }
    return dict
  }
}
