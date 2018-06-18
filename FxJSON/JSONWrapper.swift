//
//  JSON.swift
//  FxJSON
//
//  Created by Frain on 17/6/18.
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

public func wrap(_ json: JSON) -> JSON.Wrapper {
  return JSON.Wrapper(json: json)
}

public extension JSON {
  public class Wrapper {
    var json: JSON
    
    var getJSON: [(JSON) -> JSON] = []
    var setJSON: [(JSON) -> (inout JSON) -> ()] = []
    
    init(json: JSON) {
      self.json = json
    }
  }
}

public extension JSON.Wrapper {
  
  var object: Any {
    switch json {
    case .object(let any as Any),
       .array(let any as Any),
       .string(let any as Any),
       .bool(let any as Any),
       .error(let any as Any):
      return any
    case .number(let number):
      return number.object
    case .null:
      return JSON.Null()
    }
  }
  
  var type: Any.Type {
    switch json {
    case .object: return [String: Any].self
    case .array: return [Any].self
    case .string: return String.self
    case .number: return JSON.Number.self
    case .bool: return Bool.self
    case .error: return Error.self
    case .null: return JSON.Null.self
    }
  }
  
  var isNull: Bool {
    if case .null = json { return true }
    return false
  }
  
  var isError: Bool {
    if case .error = json { return true }
    return false
  }
  
  var error: Swift.Error? {
    if case let .error(error) = json { return error }
    return nil
  }
}

public extension JSON.Wrapper {
  
  func jsonData(withOptions opt: JSONSerialization.WritingOptions = []) throws -> Data {
    guard JSONSerialization.isValidJSONObject(object) else {
      throw error ?? JSON.Error.encodeToJSON(wrongObject: object)
    }
    return try JSONSerialization.data(withJSONObject: object, options: opt)
  }
  
  func jsonString(withOptions opt: JSONSerialization.WritingOptions = [],
                  encoding ecd: String.Encoding = String.Encoding.utf8) throws -> String {
    switch json {
    case .object, .array:
      let data = try self.jsonData(withOptions: opt)
      if let jsonSrt = String(data: data, encoding: ecd) { return jsonSrt }
      throw JSON.Error.encodeToJSON(wrongObject: ecd)
    default:
      throw error ?? JSON.Error.encodeToJSON(wrongObject: object)
    }
  }
}

//MARK: - StringConvertible

extension JSON.Wrapper: CustomStringConvertible, CustomDebugStringConvertible {
  
  public var description: String {
    return (try? jsonString(withOptions: .prettyPrinted)) ?? "\(object)"
  }
  
  public var debugDescription: String {
    return "\(type): " + ((try? jsonString()) ?? "\(object)")
  }
}

extension JSON.Number: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    return String(describing: object)
  }
  
  public var debugDescription: String {
    return String(describing: object)
  }
}

//MARK: - For - in

public extension JSON.Wrapper {
  
  var dict: [String: Any]? {
    guard case let .object(dic) = json else { return nil }
    return dic
  }
  
  var array: [Any]? {
    guard case let .array(arr) = json else { return nil }
    return arr
  }
  
  var asDict: LazyMapCollection<[String: Any], (key: String, value: JSON)> {
    return (dict ?? [:]).lazy.map { ($0.0, JSON(any: $0.1)) }
  }
  
  var asArray: LazyMapCollection<[Any], JSON> {
    return (array ?? []).lazy.map { JSON(any: $0) }
  }
}

//MARK: - Subscript

private extension JSON.Wrapper {
  
  func setJSON(with value: JSON) -> (inout JSON) -> () {
    guard !setJSON.isEmpty else { return { $0 = value } }
    let (get, set) = (getJSON.remove(at: 0), setJSON.remove(at: 0))
    return { json in
      var subJSON = get(json)
      self.setJSON(with: value)(&subJSON)
      if case .error = subJSON { json = subJSON; return }
      set(subJSON)(&json)
    }
  }
}

extension JSON.Wrapper {
  
  func set(json: JSON) {
    setJSON(with: json)(&self.json)
  }
}

public extension JSON.Wrapper {
  
  subscript(ignoreIfNull path: JSONKeyConvertible...) -> JSON.Wrapper {
    getJSON.append { $0[ignoreIfNull: path] }
    setJSON.append { value in { (json: inout JSON) in json[ignoreIfNull: path] = value } }
    return self
  }
  
  subscript(path: JSONKeyConvertible...) -> JSON.Wrapper {
    getJSON.append { $0[create: path] }
    setJSON.append { value in { (json: inout JSON) in json[create: path] = value } }
    return self
  }
  
  subscript(index: JSONKeyConvertible) -> JSON.Wrapper {
    getJSON.append { $0[create: index] }
    setJSON.append { value in { (json: inout JSON) in json[create: index] = value } }
    return self
  }
  
  subscript(transform: Transform) -> JSON.Wrapper {
    getJSON.append { $0[transform] }
    setJSON.append { value in { (json: inout JSON) in json[transform] = value } }
    return self
  }
}
