//
//  Collection.swift
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

extension JSON: MutableCollection {
    
  public enum Index: Comparable {
    
    public enum Key: CustomStringConvertible {
      
      case index(DictionaryIndex<String, Any>)
      case key(String)
      
      public var description: String {
        switch self {
        case .index(let v): return "\(v)"
        case .key(let v): return v
        }
      }
    }
    
    case key(Key)
    case index(Int)
    case path([JSON.Index])
  }
    
  public var startIndex: JSON.Index {
    switch self {
    case let .object(dict):
      return .key(.index(dict.startIndex))
    case let .array(arr):
      return .index(arr.startIndex)
    default:
      return .path([])
    }
  }
  
  public var endIndex: JSON.Index {
    switch self {
    case let .object(dict):
      return .key(.index(dict.endIndex))
    case let .array(arr):
      return .index(arr.endIndex)
    default:
      return .path([])
    }
  }
  
  public func index(after i: JSON.Index) -> JSON.Index {
    switch (i, self) {
    case let (.key(.index(v)), .object(dict)):
      return .key(.index(dict.index(after: v)))
    case let (.index(v), .array(arr)):
      return .index(arr.index(after: v))
    default:
      return .path([])
    }
  }
}

public extension JSON {
  
  subscript(path: JSON.Index...) -> JSON {
    get {
      return self[path]
    }
    set {
      self[path] = newValue
    }
  }
    
  subscript(index: JSON.Index) -> JSON {
    get {
      switch index {
      case let .key(v): return self[v]
      case let .index(v): return self[v]
      case let .path(v): return self[v]
      }
    }
    set {
      switch index {
      case let .key(v): self[v] = newValue
      case let .index(v): self[v] = newValue
      case let .path(v): self[v] = newValue
      }
    }
  }
  
  subscript(transform: Transform) -> JSON {
    get {
      guard !isError, let from = transform.fromJSONFunc else { return self }
      guard let ojbect = transform.jsonObjectType.init(self) else {
        return .error(Error.deserilize(from: self, to: transform.jsonObjectType))
      }
      return JSON.init(try from(ojbect))
    }
    set {
      if !newValue.isError, let to = transform.toJSONFunc {
        if let jsonObject = transform.objectType.init(newValue) {
          self = JSON.init(try to(jsonObject)); return
        }
        self = .error(Error.deserilize(from: newValue, to: transform.objectType)); return
      }
      self = newValue
    }
  }
}

extension JSON {
  
  subscript(nonNull path: [JSON.Index]) -> JSON {
    get {
      return self[create: path]
    }
    set {
      if newValue.isNull { return }
      self[create: path] = newValue
    }
  }
  
  subscript(create index: JSON.Index) -> JSON {
    get {
      switch index {
      case let .key(v): return self[create: v]
      case let .index(v): return self[create: v]
      case let .path(v): return self[create: v]
      }
    }
    set {
      switch index {
      case let .key(v): self[create: v] = newValue
      case let .index(v): self[create: v] = newValue
      case let .path(v): self[create: v] = newValue
      }
    }
  }
  
  subscript(path: [JSON.Index]) -> JSON {
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
  
  subscript(create path: [JSON.Index]) -> JSON {
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
  
  subscript(key: Index.Key) -> JSON {
    get {
      switch (self, key) {
      case let (.object(dict), .key(key)):
        if let o = dict[key] { return JSON(any: o) }
        return .error(Error.notExist(dict: dict, key: key))
      case let (.object(dict), .index(index)):
        return JSON(any: dict[index].value)
      case (.error, _):
        return self
      default:
        return .error(Error.wrongType(subscript: self, key: .key(key)))
      }
    }
    set {
      if case var .object(dict) = self {
        switch key {
        case let .key(key): dict[key] = newValue.object
        case let .index(index): dict[dict[index].key] = newValue.object
        }
        self = .object(dict)
      }
    }
  }
  
  subscript(create key: Index.Key) -> JSON {
    get {
      switch (self, key) {
      case let (.object(dict), .key(key)):
        guard let any = dict[key] else { return JSON() }
        return JSON(any: any)
      case let (.object(dict), .index(index)):
        return JSON(any: dict[index].value)
      case (.error, _):
        return self
      default:
        return JSON()
      }
    }
    set {
      if case var .object(dict) = self {
        switch key {
        case let .key(key): dict[key] = newValue.object
        case let .index(key): dict[dict[key].key] = newValue.object
        }
        self = .object(dict)
      } else if case let .key(key) = key {
        self = .object([key: newValue.object])
      }
    }
  }
  
  subscript(index: Int) -> JSON {
    get {
      switch self {
      case let .array(arr):
        if case 0..<arr.count = index { return JSON(any: arr[index]) }
        return .error(Error.outOfBounds(arr: arr, index: index))
      case .error:
        return self
      default:
        return .error(Error.wrongType(subscript: self, key: .index(index)))
      }
    }
    set {
      if case var .array(arr) = self, case 0..<arr.count = index  {
        arr[index] = newValue.object
        self = .array(arr)
      }
    }
  }
  
  subscript(create index: Int) -> JSON {
    get {
      switch self {
      case let .array(arr) where index < arr.count && index >= 0:
        return JSON(any: arr[index])
      case .error:
        return self
      default:
        return JSON()
      }
    }
    set {
      switch self {
      case var .array(arr) where index >= 0:
        if index >= arr.count {
          for _ in 0...index - arr.count { arr.append(NSNull()) }
        }
        arr[index] = newValue.object
        self = .array(arr)
      case _ where index >= 0:
        var arr = [Any](repeating: NSNull(), count: index + 1)
        arr[index] = newValue.object
        self = .array(arr)
      default:
        return
      }
    }
  }
}

//MARK: JSON.Index extension

extension JSON.Index: ExpressibleByArrayLiteral {
  
  public init(arrayLiteral elements: JSON.Index...) {
    self = .path(elements)
  }
}

extension JSON.Index: ExpressibleByStringLiteral {
  
  public init(stringLiteral value: String) {
    self = .key(.key(value))
  }
  
  public init(unicodeScalarLiteral value: String) {
    self = .key(.key(value))
  }
  
  public init(extendedGraphemeClusterLiteral value: String) {
    self = .key(.key(value))
  }
}

extension JSON.Index: ExpressibleByIntegerLiteral {
  
  public init(integerLiteral value: Int) {
    self = .index(value)
  }
}

extension JSON.Index: CustomStringConvertible {
  
  public var description: String {
    switch self {
    case let .index(v): return v.description
    case let .key(v): return "\"\(v)\""
    case let .path(v): return v.description
    }
  }
}

public func ==(lhs: JSON.Index, rhs: JSON.Index) -> Bool {
  switch (lhs, rhs) {
  case let (.key(.key(l)), .key(.key(r))):
    return l == r
  case let (.key(.index(l)), .key(.index(r))):
    return l == r
  case let (.index(l), .index(r)):
    return l == r
  case let (.path(l), .path(r)):
    return l == r
  default:
    return false
  }
}

public func <(lhs: JSON.Index, rhs: JSON.Index) -> Bool {
    switch (lhs, rhs) {
    case let (.key(.key(l)), .key(.key(r))):
        return l < r
    case let (.key(.index(l)), .key(.index(r))):
        return l < r
    case let (.index(l), .index(r)):
        return l < r
    default:
        return false
    }
}
