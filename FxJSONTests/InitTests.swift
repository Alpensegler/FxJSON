//
//  InitTests.swift
//  FxJSON
//
//  Created by Frain on 7/24/16.
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

class InitTests: XCTestCase {
	
	lazy var data: Data = {
		guard
      let file = Bundle(for: InitTests.self).path(forResource: "Example", ofType: "json"),
			let data = try? Data(contentsOf: URL(fileURLWithPath: file))
      else { fatalError("Can't find the test JSON file") }
		return data
	}()
	
	func testData() {
    let json = JSON(jsonData: data)
		XCTAssertEqual(json["web-app"]["servlet"].asArray.count, 5)
    _ = try! json.jsonData()
	}
	
	func testDataMeasure() {
		self.measure() {
			for _ in 1...100 {
        _ = JSON(jsonData: self.data)
			}
		}
	}
    
  func testWrongData() {
    let data = Data()
    guard case JSON.Error.initalize? = JSON(jsonData: data).error else { XCTFail(); return }
    let json: JSON = false
    XCTAssertThrowsError(try json.jsonData()) { (error) in
      guard case .encodeToData? = (error as? JSON.Error) else { XCTFail(); return }
    }
  }
	
	func testDic() {
		let dic = ["one": 1, "2": "two", "arr": ["aaa", "bbb", "ccc"]] as [String : Any]
		let json: JSON = ["one": 1, "2": "two", "arr": ["aaa", "bbb", "ccc"]]
		XCTAssertEqual(json.object as? NSDictionary, dic as NSDictionary)
		XCTAssertEqual(json, JSON(any: dic))
	}
	
	func testArr() {
		let arr = ["one", 123.123, "hihi hi", 4, 0.0] as [Any]
		let json: JSON = ["one", 123.123, "hihi hi", 4, 0.0]
		XCTAssertEqual(json.object as? NSArray , arr as NSArray)
		XCTAssertEqual(json, JSON(any: arr))
	}
	
	func testString() {
		let s = "need to test more!😲😣😝"
		let json: JSON = "need to test more!😲😣😝"
		XCTAssertEqual(json.object as? String, s)
		XCTAssertEqual(json, JSON(any: s))
	}
	
	func testBool() {
		let t = true
		let tjson: JSON = true
		XCTAssertEqual(tjson.object as? Bool, t)
    XCTAssertEqual(tjson, JSON(any: true))
		let f = false
		let fjson: JSON = false
		XCTAssertEqual(fjson.object as? Bool, f)
    XCTAssertEqual(fjson, JSON(any: false))
	}
	
	func testNumber() {
		let json: JSON = 1234567890.123456
    XCTAssertEqual(json, JSON(any: 1234567890.123456))
		XCTAssertEqual(json.object as? Int, 1234567890)
		XCTAssertEqual(json.object as? Double, 1234567890.123456)
		XCTAssertEqual(json.object as? Float, 1234567890.123456)
	}
	
	func testNil() {
		let json: JSON = nil
		XCTAssertTrue(json.isNull)
		XCTAssertEqual(json.object as? NSNull, NSNull())
	}
}

