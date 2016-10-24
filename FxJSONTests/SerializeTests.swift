//
//  SerializeTests.swift
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

class SerializeTests: XCTestCase {
	
	func testSerialize() {
		XCTAssertEqual("why so serious".json, JSON("why so serious"))
		XCTAssertEqual(true.json, JSON(true))
		XCTAssertEqual(1.json, JSON(1))
		XCTAssertEqual(Int32(32).json, JSON(32))
		XCTAssertEqual(Int64(64).json, JSON(64))
		XCTAssertEqual(Float(1234.567).json, JSON(Float(1234.567)))
		XCTAssertEqual(Double(1234.5678).json, JSON(1234.5678))
		
		let url = URL(string: "https://github.com/FrainL")
		XCTAssertEqual(url?.json, JSON("https://github.com/FrainL"))
		
		XCTAssertEqual(["one", 2, 3.3, Double(4)].json,
		               JSON(["one", 2, 3.3, Double(4)]))
		
		let option: Int? = nil
		XCTAssertEqual(option.json, JSON())
		XCTAssertEqual(Optional.some(Any.self).json, JSON())
		XCTAssertEqual(Optional.some("some").json, JSON("some"))
		
		let set: Set = ["hey", "fine?", "all right"]
		XCTAssertEqual(set.json, JSON(["hey", "fine?", "all right"]))
		
		let json: JSON = [
			"arr": ["one", 2, 3.3, Double(4)],
			"opt": option,
			"set": set
		]
		let dic: [String: Any] = [
			"arr": ["one", 2, 3.3, Double(4)],
			"opt": option,
			"set": set
		]
		print(XCTAssertEqual(dic.json, json))
		
		XCTAssertEqual([].json, JSON([]))
		XCTAssertEqual([:], JSON([:]))
	}
	
	func testDeSerialize() {
		XCTAssertEqual("1234.5678", String(JSON("1234.5678")))
		
		XCTAssertEqual(false, Bool.init(JSON(false)))
		
		XCTAssertEqual(123, Int(JSON(123)))
		
		XCTAssertEqual(Int32(123), Int32(JSON(123)))
		
		XCTAssertEqual(Int64(123), Int64(JSON(123)))
		
		XCTAssertEqual(Float(1234.567), Float(JSON(1234.567)))
		
		XCTAssertEqual(Double(1234.5678), Double(JSON(1234.5678)))
		
		XCTAssertEqual(URL(JSON("https://github.com/FrainL")),
		               URL(string: "https://github.com/FrainL"))
	}
}
