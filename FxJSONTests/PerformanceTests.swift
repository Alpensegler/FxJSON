//
//  PerformanceTests.swift
//  SweeftyJSON
//
//  Created by Frain on 7/27/16.
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

import XCTest

import XCTest

let json = JSON([
	"string": "string",
	"int": 42,
	"double": 42,
	"float": 42,
	"bool": true,
	"array": ["one", "two", "three"],
	"dictionary": ["string": "string", "int": 42]
] as [String : Any])

struct Struct {
	let string: String
	let int: Int
	let double: Double
	let float: Float
	let bool: Bool
	let array: [Any]
	let dictionary: [String: Any]
	let optionalFloat: Float?
	let optionalString: String?
	let optionalInt: Int?
	let optionalDouble: Double?
	let optionalBool: Bool?
	let optionalArray: [Any]?
	let optionalDictionary: [String: Any]?
	
	init(json: JSON) {
		string = String(value: json["string"])
		int = Int(value: json["int"])
		double = Double(value: json["double"])
		float = Float(value: json["float"])
		bool = Bool(value: json["bool"])
		array = json["array"].rawArray
		dictionary = json["dictionary"].rawDic
		optionalFloat = Float(json["optionalFloat"])
		optionalString = String(json["optionalString"])
		optionalInt = Int(json["optionalInt"])
		optionalDouble = Double(json["optionalDouble"])
		optionalBool = Bool.init(json["optionalBool"])
		optionalArray = json["optionalArray"].array
		optionalDictionary = json["optionalDictionary"].dic
	}
}

class PerformanceTests: XCTestCase {
	
	func test100time() {
		measure {
			for _ in 0..<100 {
				let _ = Struct(json: json)
			}
		}
	}
	
	func test1000time() {
		measure {
			for _ in 0..<1000 {
				let _ = Struct(json: json)
			}
		}
	}
	
	func test10000time() {
		measure {
			for _ in 0..<10000 {
				let _ = Struct(json: json)
			}
		}
	}
}
