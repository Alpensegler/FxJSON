//
//  Subscript.swift
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

private func errorJSON(_ des: String) -> JSON {
    return JSON(object: JSON.makeError(des, code: .subscript))
}

private extension JSON {
    
    func get(_ operate: (JSON) throws -> JSONSerializable) -> JSON {
        do {
            return try operate(self).json
        } catch let error as NSError {
            return JSON(object: error)
        }
    }
}

extension JSON: MutableCollection {
    
    public enum Index : ExpressibleByArrayLiteral, ExpressibleByStringLiteral,
    ExpressibleByIntegerLiteral, CustomStringConvertible, Comparable {
        
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
        switch self.object {
        case let dic as [String : Any]:
            return .key(.index(dic.startIndex))
        case let arr as [Any]:
            return .index(arr.startIndex)
        default:
            return .path([])
        }
    }
    
    public var endIndex: JSON.Index {
        switch self.object {
        case let dic as [String : Any]:
            return .key(.index(dic.endIndex))
        case let arr as [Any]:
            return .index(arr.endIndex)
        default:
            return .path([])
        }
    }
    
    public func index(after i: JSON.Index) -> JSON.Index {
        switch (i, object) {
        case let (.key(.index(v)), dic as [String : Any]):
           return .key(.index(dic.index(after: v)))
        case let (.index(v), arr as [Any]):
            return .index(arr.index(after: v))
        default:
            return .path([])
        }
    }
}

public extension JSON {
	
	subscript(noneNull path: JSON.Index...) -> JSON {
		get {
			if isError { return self }
			return self[path: path]
		}
		set {
			if newValue.dontSet || newValue.isNull { return }
			newValue.isError ? self = newValue : (self[path: path] = newValue)
		}
	}
	
	subscript(path: JSON.Index...) -> JSON {
		get {
			if isError { return self }
			return self[path: path]
		}
		set {
			if newValue.dontSet { return }
			newValue.isError ? self = newValue : (self[path: path] = newValue)
		}
	}
    
    subscript(index: JSON.Index) -> JSON {
        get {
            if isError { return self }
            return self[index: index]
        }
        set {
            if newValue.dontSet { return }
            newValue.isError ? self = newValue : (self[index: index] = newValue)
        }
    }
	
	subscript(transform: TransformType) -> JSON {
		get {
            return isError || isCreating ? self : get(transform.transformFrom)
		}
		set {
            switch (newValue.dontSet, newValue.isError) {
            case (true, _): self.dontSet = true
            case (_, true): self = newValue
            default: self = newValue.get(transform.transformTo)
            }
		}
	}
}

extension JSON {
	
	subscript(index index: JSON.Index) -> JSON {
		get {
			switch index {
			case let .index(v): return self[index: v]
			case let .key(v): return self[key: v]
			case let .path(v): return self[path: v]
			}
		}
		set {
			switch index {
			case let .index(v): self[index: v] = newValue
			case let .key(v): self[key: v] = newValue
			case let .path(v): self[path: v] = newValue
			}
		}
	}
	
	subscript(path path: [JSON.Index]) -> JSON {
		get {
			return path.reduce(self) { $0[index: $1] }
		}
		set {
			if path.isEmpty {
				self = newValue
			} else {
				var path = path
				let first = path.remove(at: 0)
				self[index: first][path: path] = newValue
			}
		}
	}
	
	subscript(key v: Index.Key) -> JSON {
		get {
			switch (isCreating, object) {
			case (false, let dic as [String : Any]):
                switch v {
                case .index(let v): return JSON(object: dic[v].value)
                case .key(let v): if let o = dic[v] { return JSON(object: o) }
                }
				return errorJSON("Dict[\(v)] does not exist")
			case (false, _):
				return errorJSON("Dict[\(v)] failure, its not a dictionary")
			case (true, let dic as [String : Any]):
                guard case let .key(v) = v else { fallthrough }
				return JSON(create: dic[v])
			case (true, _):
				return JSON(create: NSNull())
			}
		}
		set {
			switch (isCreating, object) {
			case (_, var dic as [String : Any]):
                switch v {
                case let .index(v): dic[dic[v].key] = newValue.object
                case let .key(v): dic[v] = newValue.object
                }
				self.object = dic as Any
			case (true, _):
                switch v {
                case .index(_): self.object = NSNull()
                case .key(let v): self.object = [v : newValue.object]
                }
			default:
				return
			}
		}
	}
	
	subscript(index v: Int) -> JSON {
		get {
			switch (isCreating, object) {
			case (false, let arr as [Any]):
				if v > arr.count - 1 || v < 0 {
					return errorJSON("Array[\(v)] is out of bounds")
				}
                return JSON(object: arr[v])
			case (false, _):
				return errorJSON("Array[\(v)] failure, its not an array")
			case (true, let arr as [Any]) where v < arr.count && v >= 0:
				return JSON(create: arr[v])
			case (true, _):
				return JSON(create: NSNull())
			}
		}
		set {
			switch (isCreating, object) {
			case (false, var arr as [Any]) where v < arr.count && v >= 0:
				arr[v] = newValue.object
				self.object = arr as Any
			case (true, var arr as [Any]) where v >= 0:
				if v >= arr.count {
					for _ in 0...v - arr.count { arr.append(NSNull()) }
				}
				arr[v] = newValue.object
				self.object = arr as Any
			case (true, _) where v >= 0:
				var arr: [Any] = []
				for _ in 0...v { arr.append(NSNull()) }
				arr[v] = newValue.object
				self.object = arr as Any
			default:
				return
			}
		}
	}
}

public extension JSON.Index {
	
	init(stringLiteral value: String) {
		self = .key(.key(value))
	}
	
	init(unicodeScalarLiteral value: String) {
		self = .key(.key(value))
	}
	
	init(extendedGraphemeClusterLiteral value: String) {
		self = .key(.key(value))
	}
	
	init(integerLiteral value: Int) {
		self = .index(value)
	}
	
	init(arrayLiteral elements: JSON.Index...) {
		self = .path(elements)
	}
	
	var description: String {
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
