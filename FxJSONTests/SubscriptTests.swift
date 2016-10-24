//
//  SubscriptTests.swift
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
@testable import FxJSON

class SubscriptTests: XCTestCase {
	
	var json: JSON = [
		"arr": [1234567890.123456, 12345, 0.123456, 0, [[NSNull(),[1]]]],
		"dic": [
			"str1": "same@#$%^&*()!",
			"str2": "中文当然也得一样😲",
			"str3": "日本語も同じです😝",
			"true": true,
			"false": false,
			"null": NSNull(),
			"dic": [
				"key": "you found a str here!",
				"arr": [-1]
			]
		],
		"t1": 0.0,
		"t2": Date(timeIntervalSince1970: 0).timeIntervalSinceReferenceDate,
		"t3": Date(timeInterval: NSTimeIntervalSince1970,
			since: Date(timeIntervalSince1970: NSTimeIntervalSince1970))
			.timeIntervalSinceReferenceDate,
		"t4": "2001-01-01 08:00:00",
        "one": 1
	]
	
	func testArray() {
		XCTAssertEqual(json["arr", 0], 1234567890.123456)
		XCTAssertEqual(json["arr", 1], 12345)
		XCTAssertEqual(json["arr", 2], 0.123456)
		XCTAssertEqual(json["arr", 3], 0)
		XCTAssertEqual(json["arr", 4, 0, 1, 0], 1)
		XCTAssertEqual(json["t3"].object as? Double, NSTimeIntervalSince1970)
        
    guard case JSON.Error.wrongType? = json["arr", "two"].error else { XCTFail(); return }
    guard case JSON.Error.outOfBounds? = json["arr", -1].error else { XCTFail(); return }
    guard case JSON.Error.outOfBounds? = json["arr", 5].error else { XCTFail(); return }
		
		json["arr", 0] = 1.9
		json["arr", 1] = 2.899
		json["arr", 2] = 3.567
		json["arr", 3] = 0
		json["arr"][4][0][0] = 0
		
		XCTAssertEqual(json["arr", 1].object as? Float, 2.899)
		XCTAssertEqual(json["arr", 2].object as? Double, 3.567)
		XCTAssertEqual(json["arr", 3].object as? Int, 0)
		XCTAssertEqual(json["arr"][4][0][0], 0)
	}
	
	func testDic() {
		XCTAssertEqual(json["dic", "str1"].object as? String, "same@#$%^&*()!")
		XCTAssertEqual(json["dic", "str2"], "中文当然也得一样😲")
		XCTAssertEqual(json["dic", "str3"], "日本語も同じです😝")
		XCTAssertEqual(json["dic", "true"].object as? Bool, true)
		XCTAssertEqual(json["dic", "false"], false)
		XCTAssertEqual(json["dic", "dic", "key"], "you found a str here!")
		XCTAssertEqual(json["dic"]["dic"]["key"], "you found a str here!")
		XCTAssertEqual(json["dic", "dic", "arr", 0], -1)
		XCTAssertEqual(json["dic"]["dic"]["arr"][0], -1)
		XCTAssertEqual(json["t4"], "2001-01-01 08:00:00")
        
    guard case JSON.Error.wrongType? = json["dic", 0].error else { XCTFail(); return }
    guard case JSON.Error.notExist? = json["dic", "str4"].error else { XCTFail(); return }
		
		json["dic", "str1"] = "Pratice more."
		json["dic", "str2"] = "还需要多做一点！😲"
		json["dic", "str3"] = "頑張って！😝"
		json["dic", "str4"] = "其实都唔知做咩..."
		
		XCTAssertEqual(json["dic", "str1"].object as? String, "Pratice more.")
		XCTAssertEqual(json["dic", "str2"], "还需要多做一点！😲")
		XCTAssertEqual(json["dic", "str3"].description, "\"頑張って！😝\"")
		XCTAssertEqual(json["dic", "str4"], "其实都唔知做咩...")
	}
	
	
	func testTime() {
		XCTAssertEqual(Date(json["t1"][DateTransform.timeIntervalSince(.year1970)]),
		               Date(timeIntervalSince1970: 0))
		XCTAssertEqual(Date(json["t2"][DateTransform.timeIntervalSince(.referenceDate)]),
		               Date(timeIntervalSince1970: 0))
    let date = Date(timeIntervalSince1970: NSTimeIntervalSince1970)
		XCTAssertEqual(Date(json["t3"][DateTransform.timeIntervalSince(.date(date))]),
		               Date(timeIntervalSinceReferenceDate: NSTimeIntervalSince1970))
		XCTAssertEqual(Date(json["t4"]),
		               Date(timeIntervalSinceReferenceDate: 0))
        
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    
    guard case JSON.Error.formatter? = json["t4"][DateTransform.formatter(formatter)].error else { XCTFail(); return }
    
		json["t5"] = 978307200.0
    json["t6"][DateTransform.formatter(formatter)] = Date(
    timeIntervalSinceReferenceDate: 0).json
    
    let `default` = DateTransform.default
    defer { DateTransform.default = `default` }
    DateTransform.default = DateTransform.timeIntervalSince(.year1970)
    
		XCTAssertEqual(Date(json["t5"]),
		               Date(timeIntervalSinceReferenceDate: 0))
		XCTAssertEqual(json["t6"], "2001-01-01")
	}
    
  func testTransform() {
    let form = CustomTransform.fromJSON { (int: Int) throws -> String in
      return "\(int)"
    }
    XCTAssertEqual(json["one"][form], "1")
    
    let errorTransform = CustomTransform<Int, Int>.fromJSON { int in
      throw JSON.Error.customTransfrom(source: int)
    }
    
    guard case .some(JSON.Error.customTransfrom) = json["one"][errorTransform].error else { XCTFail(); return }
    
    let to = CustomTransform.toJSON { (str: String) throws -> Int in
      if let num = Int(str) { return num }
      throw JSON.Error.customTransfrom(source: str)
    }
    
    json["two"][to] = "2"
    json["three"][to] = "three"
    
    XCTAssertEqual(json["two"], 2)
    
    guard case JSON.Error.customTransfrom? = json["three"].error else { XCTFail(); return }
  }

	func testCreat() {
		var createJson = JSON()
    createJson[create: "arr"] = [NSNull(), 12345, 0.123456, 0]
    createJson[create: "arr"][create: 0] = 1234567890.123456
    createJson[create: ["arr", 4, 0, 1, 0]] = 1
		
		XCTAssertEqual(json["arr"], createJson["arr"])
		
    createJson[create: "dic"] = [
      "str1": "same@#$%^&*()!",
      "str2": "中文当然也得一样😲",
      "str3": "日本語も同じです😝"
    ]

    createJson[create: ["dic", "null"]] = nil
    createJson[create: ["dic", "true"]] = true
    createJson[create: ["dic", "false"]] = false

    createJson[create: ["dic", "dic", "key"]] = "you found a str here!"
    createJson[create: ["dic", "dic", "arr"]] = [-1]
    
		XCTAssertEqual(json["dic"], createJson["dic"])
		
    createJson[create: "t1"] = 0
    createJson[create: "t2"] = (NSTimeIntervalSince1970 * -1).json
    createJson[create: "t3"] = NSTimeIntervalSince1970.json
    createJson[create: "t4"][DateTransform.default] = Date(timeIntervalSinceReferenceDate: 0).json
    createJson[create: "one"] = 1
		
		XCTAssertEqual(json, createJson)
	}
}
