//
//  Subscript.swift
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

//MARK: - Subscript

public protocol JSONKeyConvertible {
  var key: String { get }
}

extension JSONKeyConvertible where Self: CustomStringConvertible {
  public var key: String {
    return description
  }
}

extension String: JSONKeyConvertible { }
extension Int: JSONKeyConvertible { }

public extension JSON {
  
  typealias KeyPath = WritableKeyPath<JSON, JSON>
  
  subscript(dynamicMember key: String) -> JSON {
    get {
      switch (self, Int(key)) {
      case let (.array(arr), index?):
        if arr.indices.contains(index) { return JSON(any: arr[index]) }
        return .error(Error.outOfBounds(arr: arr, index: index))
      case let (.object(dict), _):
        if let o = dict[key] { return JSON(any: o) }
        return .error(Error.notExist(dict: dict, key: key))
      case (.error, _):
        return self
      default:
        return .error(Error.wrongType(subscript: self, key: key))
      }
    }
    set {
      switch (self, Int(key)) {
      case (.null, let index?):
        guard index == 0 else { return }
        self = .array([wrap(newValue)])
      case (.null, _):
        self = .object([key: wrap(newValue).object])
      case (var .array(arr), let index?):
        guard arr.indices.contains(index) else { return }
        arr[index] = wrap(newValue).object
        self = .array(arr)
      case var (.object(dict), _):
        dict[key] = wrap(newValue).object
        self = .object(dict)
      default:
        break
      }
    }
  }
  
  subscript(path: JSONKeyConvertible...) -> JSON {
    get {
      return self[path]
    }
    set {
      self[path] = newValue
    }
  }
  
  subscript(path: [JSONKeyConvertible]) -> JSON {
    get {
      return path.reduce(self) { $0[$1] }
    }
    set {
      guard !path.isEmpty else { self = newValue; return }
      var path = path
      let first = path.remove(at: 0)
      self[first][path] = newValue
    }
  }
  
  subscript(key: JSONKeyConvertible) -> JSON {
    get {
      return self[dynamicMember: key.key]
    }
    set {
      self[dynamicMember: key.key] = newValue
    }
  }
  
  subscript(transform: Transform) -> JSON {
    get {
      guard !wrap(self).isError, let from = transform.fromJSONFunc else { return self }
      return JSON.init(try from(transform.jsonObjectType.init(decode: self)))
    }
    set {
      guard !wrap(newValue).isError, let to = transform.toJSONFunc else { self = newValue; return }
      self = JSON.init(try to(transform.objectType.init(decode: newValue)))
    }
  }
}

extension JSON {
  
  subscript(ignoreIfNull path: [JSONKeyConvertible]) -> JSON {
    get {
      return self[create: path]
    }
    set {
      if wrap(newValue).isNull { return }
      self[create: path] = newValue
    }
  }
  
  subscript(create path: [JSONKeyConvertible]) -> JSON {
    get {
      return path.reduce(self) { $0[create: $1] }
    }
    set {
      guard !path.isEmpty else { self = newValue; return }
      var path = path
      let first = path.remove(at: 0)
      self[create: first][create: path] = newValue
    }
  }

  subscript(create key: JSONKeyConvertible) -> JSON {
    get {
      switch (self, Int(key.key)) {
      case let (.array(arr), index?):
        if arr.indices.contains(index) { return JSON(any: arr[index]) }
        return .error(Error.outOfBounds(arr: arr, index: index))
      case let (.object(dict), _):
        if let o = dict[key.key] { return JSON(any: o) }
        return .error(Error.notExist(dict: dict, key: key.key))
      case (.error, _):
        return self
      default:
        return JSON()
      }
    }
    set {
      switch (self, Int(key.key)) {
      case (var .array(arr), let index?):
        guard arr.indices.contains(index) else { return }
        arr[index] = wrap(newValue).object
        self = .array(arr)
      case var (.object(dict), _):
        dict[key.key] = wrap(newValue).object
        self = .object(dict)
      default:
        break
      }
    }
  }
}
