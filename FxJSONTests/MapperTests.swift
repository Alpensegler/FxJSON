//
//  MapperTests.swift
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

class MapperTests: XCTestCase {
  
  let json = SubscriptTests().json
  
  func testCreateMapping() {
    
    let date = Date(timeIntervalSince1970: NSTimeIntervalSince1970)
    
    let createJSON = JSON {
      $0["arr"] << JSON {
        $0 << [NSNull(), 12345, 0.123456, 0]
        $0[0] << 1234567890.123456
        $0[4, 0, 1, 0] << 1
      }
      $0["dic"] << JSON {
        $0 << [
          "str1": "same@#$%^&*()!",
          "str2": "中文当然也得一样😲",
          "str3": "日本語も同じです😝"
        ]
        $0["null"] << NSNull()
        $0[nonNull: "nonNil"] << NSNull()
        $0["true"] << true
        $0["false"] << false
        $0["dic"] << JSON {
          $0["key"] << "you found a str here!"
          $0["arr"]  << [-1]
        }
      }
      $0["t1"] << 0
      $0["t2"][DateTransform.timeIntervalSince(.referenceDate)]
        << Date(timeIntervalSince1970: 0)
      $0["t3"][DateTransform.timeIntervalSince(.date(date))]
        << Date(timeIntervalSinceReferenceDate: NSTimeIntervalSince1970)
      $0["t4"][DateTransform.formatter(
          { $0.dateFormat = "yyyy-MM-dd HH:mm:ss"; return $0 }(DateFormatter()))
        ]
        << Date(timeIntervalSinceReferenceDate: 0)
      $0["one"][CustomTransform<Int, String>.toJSON { Int($0)! }] << "1"
    }
  
    XCTAssertEqual(json, createJSON)
  }
  
  func testClasses() {
    
    let json = JSON {
      $0["name"]  << "test"
      $0["sub"]   << JSON {
        $0["age"]   << 20
        $0["money"]  << 17000.0
      }
      $0["age"]   << 21
      $0["tall"]  << 16900.0
      $0["some"]  << "some"
    }
    
    print(json["some"])
    
    class A: JSONMappable {
          
      var name = ""
      var age = 0
      var money = 0.0
    
      func map(mapper: JSON.Mapper) {
        name    >< mapper
        age     <> mapper["sub"]["age"]
        money   <> mapper["sub"]["money"]
      }
      
      required init() {}
    }
    
    class B: A {
      let some = ""
      
      override func map(mapper: JSON.Mapper) {
        super.map(mapper: mapper)
        age << mapper["age"]
      }
    }
    
    guard let a = A(json) else { XCTFail(); return }
    XCTAssertEqual(a.name, "")
    XCTAssertEqual(a.age, 20)
    XCTAssertEqual(a.money, 17000.0)
    
    guard case JSON.Error.notExist? = a.json["name"].error else { XCTFail(); return }
    XCTAssertEqual(a.json["sub"]["age"], 20)
    XCTAssertEqual(a.json["sub"]["money"], 17000.0)
    
    guard let b = B(json) else { XCTFail(); return }
    XCTAssertEqual(b.some, "some")
    XCTAssertEqual(b.age, 21)
    XCTAssertEqual(b.money, 17000.0)
  }
}
