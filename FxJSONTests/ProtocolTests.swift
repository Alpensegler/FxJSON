//
//  SerializeTests.swift
//  SweeftyJSON
//
//  Created by Frain on 8/27/16.
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

class ProtocolTests: XCTestCase {
    
  func testCodable() {
    
    struct A: JSONDecodable, JSONEncodable {
      
      let name: String
      let age: Int
      let gender: Gender
      
      init(decode json: JSON) throws {
        name    = try json["name"]<
        age     = try json["age"]<
        gender  = try json["gender"]<
      }
      
      enum Gender: Int, JSONTransformable {
        case boy
        case girl
      }
    }
    
    let json = ["name": "name", "age": 10, "gender": 0] as JSON
    guard let a = A.init(json) else { XCTFail(); return }
    XCTAssertEqual(a.age, 10)
    XCTAssertEqual(a.name, "name")
    XCTAssertEqual(a.gender.rawValue, A.Gender.boy.rawValue)
    
    XCTAssertEqual(a.json, json)
    
    XCTAssertThrowsError(try A.init(decode: ["name": "", "age": "10"])) { (error) in
      guard case JSON.Error.deserilize = error else { XCTFail(); return }
    }
  }
  
  func testError() {
    let json: JSON = [
      "code": 0,
      "data": [
        "users": [
          [
            "userID": 0,
            "name": "Admin",
            "admin": true,
            "website": NSNull(),
            "signUpTime": "1996-03-12 00:00:00",
            ],
          [
            "userID": 1,
            "name": "Frain",
            "admin": false,
            "website": "https://github.com/FrainL",
            "whatsUp": "buzy",
            "signUpTime": "2016-04-22 21:31:31",
            "friends": [
              ["userID": 2,"name": "box","admin": false],
              ["userID": 2,"name": "sky","admin": false]
            ]
          ]
        ]
      ]
    ]
    
    struct User: JSONMappable {
      var userID: Int64!
      var name: String!
      var admin: Bool = false
      var whatsUp: String?
      var website: URL?					//URL 自动转化
      var signUpTime: Date?			//Date 通过 DateTransform 转化
      var lastLoginDate = Date()
      var friends: [User]?			//自己的数据结构也可以转化
      
      mutating func map(mapper: JSON.Mapper) {
        admin         >< mapper
        whatsUp       <> mapper[noneNull: "whatsUp"]
        signUpTime    << mapper["signUpTime"]
        lastLoginDate >> mapper["lastLoginDate"]
      }
    }
    
    do {
      let user = try User(throws: json["data", "users", 0])
      print(user)
      print(user.json)
    } catch {
      print(error)
    }
  }
}
