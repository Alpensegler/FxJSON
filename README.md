<p align="center">
  <img src=https://raw.githubusercontent.com/FrainL/FxJSON/master/FxJSON.jpg>
</p>

<p align="center">
<a href="#features">Features</a> | <a href="#overview">Overview</a> | <a href="#installation">Installation</a> | <a href="#usage">Usage</a> | <a href="#references">References</a> | <a href="#extend">Extend</a> | <a href="#funtional-programming">Funtional Programming</a>
</p>

# Features

- [x] [快速](#它很快)
- [x] [JSON 和自定义类型互相转化](#它很好用)
- [x] [全面的转化选项](#它很全面)
- [x] [Playgrounds 示例](#1-使用-playground-查看)
- [x] [Date 转换和自定义转换方式](#4-转换)
- [x] [所有常见类型支持](#1-supported-types)
- [x] [全面灵活，面向协议](#2-protocols)
- [x] [Swifty 的错误处理](#4-errors)
- [x] [与多个主流库一同使用](#extend)
- [x] [支持函数式编程](#funtional-programming)


# Overview

#### 它很快

这里用了和  [JASON](https://github.com/delba/JASON) 相同的 [benchmarks](https://github.com/delba/JASON/tree/benchmarks)（改成了 Swift 3 的语法），见 [PerformanceTests](https://github.com/FrainL/FxJSON/blob/master/FxJSONTests/PerformanceTests.swift) 。

|            |         100          |        1000         |        10000        |    Δ    |
| ---------- | :------------------: | :-----------------: | :-----------------: | :-----: |
| FxJSON     | 0.002sec (21% STDEV) | 0.017sec (9% STDEV) | 0.170sec (9% STDEV) |    1    |
| SwiftyJSON | 0.007sec (16% STDEV) | 0.075sec (8% STDEV) | 0.678sec (8% STDEV) | 3.5~4.4 |
| JASON      | 0.009sec (10% STDEV) | 0.083sec (3% STDEV) | 0.852sec (6% STDEV) | 4.5~5.0 |

#### 它很好用

使用 `JSONCodable` 协议配合 `Struct` ，不用继承自 `NSObject` ，不用实现一个  `init()` ，不用必须写一个 `mapping`  函数，不必声明所有的属性都为  `var` ，FxJSON 默认为你支持从 `JSON` 到该结构的转化。 `Class` 也同样支持（支持[继承](#2-jsonmappable)），建议你在 [Playgrounds](#1-使用-playground-查看) 中查看。

```swift
struct User: JSONCodable {		//只需 JSONCodable 即可默认支持
  let userID: Int64
  let name: String
  let admin: Bool
  let website: URL?				//URL 默认转换
  let lastLogin: Date			//Date 通过 DateTransform.default 转换
  let friends: [User]			//自定义类型支持了协议也可以转换
}
```

#### 它很全面

或者你也可以用 `static func specificOptions() -> [String: SpecificOption]` 函数自定一些属性转换方式（可选，详见 [Options](#3-options)）。

```swift
let webTransform = CustomTransform<String, String>.fromJSON { "https://\($0)" } //自定义转化
let dateTransform = DateTransform.timeIntervalSince(.year1970) //也可设置 DateTransform.default

extension User {
  static func specificOptions() -> [String: SpecificOption] {
    return [
      "id": "userID",	//或者用 .index(["ids", 0]) 下标示地获取嵌套值
      "website": [.transform(webTransform), .ignoreIfNull],					
      "lastLogin": [.defaultValue(Date()), .transform(dateTransform)],
      "friends": .nonNil
    ]
  }
}
```

除此之外，FxJSON 提供对 `enum` 默认支持以及一个用于支持自带引用类型的 `JSONConvertable`，见 [Protocols](#2-protocols) 。

#### 它很优雅

现在你就可以和[其他支持的类型](#1-supported-types)一样通过下面这种方式来从 `JSON` 转换：

```swift
let json = JSON(jsonData: jsonData) 				// Data?
let json = JSON(jsonString: jsonString)				// String?
if let user = User(json["data", "users", 1]) {		// 支持地址式下标
  // do some thing with user
}
let users = [User](nonNil: json["data", "users"])	// nonNil 表示得到不为空的结果
```

或者直接从 `Data?` 或 `JSON` 形式的 `String?` 转换：

```swift
if let dict = try? [String: Any](jsonData: jsonData) {
  // do some thing with dict
}
```

或者使用带非常 Swifty 的[错误处理](#4-errors)方式的 `decode` 转换：

```swift
do {
  let user = try User(decode: json["data", "users", 2])
} catch let JSON.Error.outOfBounds(arr: arr, index: index) {
  // do some thing
}
```

同时，这些支持的类型还能直接转化为 `JSON` 或者 `Data`、JSON 形式的 `String`

```swift
let json = ["key": 123].json
let jsondata = try [123, 456, 789].jsonData()
let jsonString = try user.jsonString()
```

自定义 `JSON` 也很简单：

```swift
let json = ["code": 0, "data": ["users": users]] as JSON
```

甚至还能这样：

```swift
let json = JSON {
  $0["code"] << 0
  $0["data", "users"] << users
}
```

## Installation

#### Carthage 

You can use [Carthage](https://github.com/Carthage/Carthage) to install FxJSON by adding it to your `Cartfile`:

```
github "FrainL/FxJSON"
```

#### Manually

To use this library in your project manually you may:

1. for Projects, just drag all the .swift file to the project tree
2. for Workspaces, include the whole FxJSON.xcodeproj

## Usage

1. [使用 Playgrounds 查看](#1-使用-playground-查看)
2. [处理 JSON 数据](#2-处理-json-数据)
   1. [初始化](#1-初始化)
   2. [获取数据](#2-获取数据)
   3. [fot-in](#3-fot-in)
   4. [转换](#4-转换)
   5. [创建 JSON](#5-创造-json)
3. [使用 Protocol](#3-使用协议)
   1. [JSONDecodable](#1-jsondecodable)
   2. [JSONEncodable](#2-jsonencodable)
   3. [JSONConvertable](#3-jsonconvertable)

### 1. 使用 playground 查看

1. 打开 FxJSON.workspace
2. 使用 iPhone 5s 以上模拟器 build FxJSON 
3. 在 workspace 中打开 FxJSON.playground
4. 你可以在 FxJSON.playground 的

### 2. 处理 JSON 数据

#### 1. 初始化

```swift
let json = JSON(some)						//Type that supported
let json = JSON(any: any)					//Any
let json = JSON(jsonData: data)				//Data?
let json = JSON(jsonString: jsonString)		//String?
```

或者任何自带或使用 protocol 支持的自定义类型都可以直接使用 `some.json` 获取。详见[类型支持](#1-supported-types)。

#### 2. 获取数据

`JSON` 实际上是一个 `Enum` ，你可以直接用匹配模式获取数据。

```swift
if case let .string(name) = json {
  //do some thing with name
}
```

支持类似 `SwiftyJSON` 地址式的下标。

```swift
json["code"]
json["data", "users", 0]

let path: JSON.Index = ["data", "users", 1]
json[path]
json[path, "name"]
```

使用 `SupportedType(json)` 的形式可以获取 `Optional` 数据。

```swift
if let code = Int(json["code"]) {
  // do something here
}
let whatsUp = String(json[path]["whatsUp"])
```

使用 `SupportedType(nonNil: json)` 的形式可以获取非 `Optional` 数据，需要类型实现了 `DefaultInitable` ，见[类型支持](#1-supported-types)。

```swift
let userID = Int(nonNil: json[path, "userID"])
let name = String(nonNil: json[path, "name"])
```

使用 `SupportedType(decode: json)`  的形式的初始化带有错误处理。

```swift
let admin = try Bool(throws: json[path, "admin"])

do {
  let notExist = try Int(throws: json["notExist"])
} catch let JSON.Error.notExist(dict: dict, key: key) {
  // do something
}
```

`[SupportedType]` 、`[Any]`、`[String: SupportedType]`、 `[String: Any]` 同样也是支持的类型。

```swift
let user = [String: Any](json["data", "users", 0])
let friends = [[String: Any]](nonNil: json[path, "friends"])
```

### 3. fot-in

`JSON` 是一个 `MutableCollection` ，它能使用所有 `MutableCollection` 的方法，比如 `isEmpty` 、`count` 等等都能使用。

```swift
json.count
json.isEmpty
json.first
```

在使用 for-in 的时候，无论 `JSON` 是 `.array` 还是 `.object`，`Element` 都是 `JSON`  类型。

```swift
for subJSON in json {
  //do some thing
}
```

特别的，如果有需要，可以用 `.asDic` 和 `asArray` 来使用 for-in。（因为使用了 `LazyMapCollection` ，使用这两者会比直接使用 for-in 性能更好）

```swift
// If JSON is an object
for (key, subJSON) in json.asDic { 
  // do something
}
// If JSON is an array
for subJSON in json.asArray {
  // do something
}
```

### 4. 转换

通过设置 `DateTransform.default` 来更改 `Date` 的默认的转换方式。

```swift
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
DateTransform.default = DateTransform.formatter(formatter)
```

`Date` 可以通过 `DateTransform` 进行转换。（默认格式化器为 "yyyy-MM-dd'T'HH:mm:ssZ" ）

```swift
let signUpTime = Date(json[path, "signUpTime"])
let date = Date(JSON(NSTimeIntervalSince1970)[DateTransform.timeIntervalSince(.year1970)])
```

你可以你还可以通过 `CustomTransform` 来自定义转换方式，可以选用 `.toJSON` , `.fromJSON` 或 `.both` 来定义需要的转换方式（使用  `throw` 以便进行错误处理）：

```swift
let from = CustomTransform<String?, String>.fromJSON {
  if let string = $0 { return "https://\(string)" }
  throw JSON.Error.customTransfrom(source: $0)
}
let website = URL(json[path]["website"][from])

do {
  let code = try Int(decode: json["code"][from])
} catch let JSON.Error.customTransfrom(source: any) {
  //do some thing
}
```

### 5. 创造 JSON

FxJSON 能提供目前为止最为便捷的创造 JSON 的方式，使用 literal：

```swift
let userJSON: JSON = [
	"userID": userID,
	"name": name,
	"admin": admin
]
```

使用操作符 `<<`（ `ignoreIfNull` 表示右边转化为 `null` 时不插入 `JSON` ）：

```swift
let to = CustomTransform<String, String>.toJSON {
  $0.substring(from: $0.index($0.startIndex, offsetBy: 8))
}

let createJSON = JSON {
  $0["code"]             << code
  $0["data", "users"][0] << user
  $0[path]               << JSON {
    $0                     		<< userJSON
    $0[ignoreIfNull: "whatsUp"] << whatsUp
    $0["website"][to]      		<< website
    $0["signUpTime"]      		<< signUpTime
    $0["friends"]         		<< friends
  }
}
```

### 3. 使用协议

`JSONCodable` 实际上是 `JSONDecodable & JSONEncodable` 的别名。

#### 1. JSONDecodable  

`struct` 可以默认支持，`class` 需要多实现一个 `DefaultInitable` ，若 `enum` 为  `RawRepresentable` 且 ` RawValue ` 也是支持的类型，也能得到默认的支持。

使用 `JSONDecodable` 可以将 `JSON` 数据转化为自定义数据。不需要任何其他操作， FxJSON 根据你的参数名使用指针操作默认实现转换。

```swift
struct BasicStruct {
  let userID: Int64
  let name: String
  let admin: Bool
  let signUpTime: Date?
}

extension struct BasicStruct: JSONDecodable { }

let admin = BasicStruct(json["data", "users", 0])
```

当然你也可以使用 `static func specificOptions() -> [String: SpecificOption]` 来指定特定参数的转换方式，详见[Options](#3-options)：

```swift
extension BasicStruct {
  static func specificOptions() -> [String: SpecificOption] {
    return [
      "userID": ["userID", .nonNil],  // same as .index("userID")
      "admin": .defaultValue(true),
      "signUpTime": .transform(transform)
    ]
  }
}
```

当然你也可以自己实现 `init(decode json: JSON) throws`  。使用 `<` 后置操作符利用类型匹配调用 `init(decode json: JSON)` 来轻松做到这一点 。

```swift
extension BasicStruct: JSONDecodable {
  init(decode json: JSON) throws {
    userID      = try json["userID"]<
    name        = try json["name"]<
    admin       = try json["admin"]<
    signUpTime  = try json["signUpTime"]<
  }
}
```

类类型如果要默认实现，需额外实现一个 protocol `DefaultInitable` （需实现一个 `init()` 并加上  `required` ）。否则将会运行时报错。

```swift
class BasicClass: JSONDecodable, DefaultInitable {
  let userID: Int64 = 0
  let name: String = ""
  let admin: Bool = true
  let signUpTime: Date? = nil
  
  required init() { }
}
```

同样，你也可以使用 `static func specificOptions() -> [String: SpecificOption]` 来指定特定参数的转换方式，和 `struct` 中一样。

如果是继承了一个 `JSONDecodable` ，你同样只需要为新的参数添加默认值即可。若要增加新的 `SpecificOption` ，需要将父类  `static func specificOptions() -> [String: SpecificOption]` 中的 `static` 改成 `class` 并在子类中重写。

```swift
class UserClass: BasicClass {
  let website: URL?
  let friends: [BasicClass]
  
  override class func specificOptions() -> [String: SpecificOption] {
    var option = super.specificOptions()
    option["website"] = .transform(customTransform)
    return option
  }
}
```

同样你也可以自己实现，（需要在 init 前加上  `required` ）。

如果是继承了一个 `JSONDecodable` 的话，需要在 `init` 最后加上 `try super.init(decode: json)`

```swift
class UserClass: BasicClass {
  let website: URL?
  let friends: [BasicClass]
  
  required init(decode json: JSON) throws {
    website = try json["website"]<
    friends = try json["friends"]<
    try super.init(decode: json)
  }
}
```

#### 2. JSONEncodable

使用 `JSONEncodable` 可以让自定义类型支持转化为 `JSON` （ `Class` 和 `Struct` 都是一样，若 `enum` 为  `RawRepresentable` 且 ` RawValue ` 也是支持的类型，也能得到默认的支持。）同样默认通过指针操作实现。

```swift
extension BasicStruct: JSONEncodable { }
```

当然也支持指定特定参数的转换方式。

```
extension BasicStruct {
  static func specificOptions() -> [String: SpecificOption] {
    return [
      "userID": "userID",  // same as .index("userID")
      "admin": .ignore,
      "signUpTime": [.transform(transform), .ignoreIfNull]
    ]
  }
}
```

同样，`class` 若要支持继承，只需把 `static` 改成 `class` 就能在子类中重写。

如果你想更加详细地定义，你可以使用 `encode(mapper:)` 。和[创造 JSON](#5-创造-json)一样，使用 `<<` 操作符即可：

```swift
extension BasicStruct: JSONEncodable {
  func encode(mapper: JSON.Mapper) {
    mapper["userID"]             		<< userID
    mapper["name"]                		<< name
    mapper["admin"]              		<< admin
    mapper[ignoreIfNull: "signUpTime"] 	<< signUpTime
  }
}

try basicStruct.jsonData()
```

如果是 `class` 继承了一个 `JSONEncodable` ，则需要 `override` `encode(mapper:)` 然后在最后加上 `super.encode(mapper: mapper)`。

```swift
class UserClass: BasicClass {
  override func encode(mapper: JSON.Mapper) {
    mapper[ignoreIfNull: "website"] << website
    mapper["friends"]           	<< friends
    super.encode(mapper: mapper)
  }
}
```

#### 3. JSONConvertable

使用 `JSONConvertable` 来使引用类型支持从 `JSON` 转化：

```swift
extension UIColor: JSONConvertable {
  public static func convert(from json: JSON) -> Self? {
    guard let hex = Int(json) else { return nil }
    let r = (CGFloat)((hex >> 16) & 0xFF)
    let g = (CGFloat)((hex >> 8) & 0xFF)
    let b = (CGFloat)(hex & 0xFF)
    return self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
  }
}

let color = UIColor(0xFF00FF as JSON)	//purpel color
```

除此之外，知道这些已经足够，但剩余的 Protocol 你可以从 [Protocols](#2-protocols) 中找到。

## References

#### 1. Supported Types 

| Supported Type                           | Default value |
| :--------------------------------------- | ------------- |
| `String`                                 | ""            |
| `Bool`                                   | false         |
| `Float`, `Double`                        | 0.0           |
| `Int`, `Int8`, `Int16`, `Int32`, `Int64` | 0             |
| `Date`                                   | ×             |
| `URL`                                    | ×             |
| `NSNull`                                 | ×             |
| `Optional<SupportedType>`                | ×             |
| `ImplicitlyUnwrappedOptional<SupportedType>` | nil           |
| `Set<SupportedType>`                     | []            |
| `Array<SupportedType>`                   | []            |
| `Array<Any>`                             | []            |
| `Dictionary<String, SupportedType>`      | [:]           |
| `Dictionary<String, Any>`                | [:]           |

**note:**  × 表示该类型没有默认值

#### 2. Protocols

| Protocol          | 需要实现的方法                                  | 说明                                       |
| ----------------- | ---------------------------------------- | ---------------------------------------- |
| JSONTransformable | var json: JSON { get }; init?(_ json: JSON) | JSONDeserializable & JSONSerializable    |
| DefaultInitable   | init()                                   | 支持该协议并支持 JSONDeserializable 则可以使用 init(noneNull json: JSON) 方法 |
| JSONConvertable   | static func convert(from json: JSON) -> Self? | 该协议让引用类型支持从 JSON 转换                      |
| JSONDecodable     | init(decode json: JSON) throws // 可选     | 该协议让类型支持从 JSON 转换，当类型为 RawRepresentable 且 RawValue 为支持的类型时默认支持 |
| JSONEncodable     | func encode(mapper: JSON.Mapper) // 可选   | 该协议让类型支持从 JSON 转换，当类型为 RawRepresentable 且 RawValue 为支持的类型时时默认支持 |
| JSONCOdable       | init(decode json: JSON) throws; func encode(mapper: JSON.Mapper) // 可选 | JSONDecodable & JSONEncodable            |

#### 3. Options

| option            | 参数         | 生效     | 说明                                       |
| ----------------- | ---------- | ------ | ---------------------------------------- |
| .index            | JSON.Index | both   | 替代属性名来获取 JSON 数据和生成 JSON 数据              |
| .alternativeIndex | JSON.Index | decode | 当 JSON 中获取数据失败，使用这个 index                |
| .transform        | Transform  | both   | 自定义转换方式                                  |
| .defaultValue     | Any        | decode | 当 JSON 中获取数据失败，使用该数据作为值                  |
| .nonNil           | ×          | decode | 效果同 init(nonNil: json)，需要是 `DefaultInitable` |
| .ignore           | ×          | encode | 转换为 JSON 时忽略这个属性                         |
| .ignoreIfNull     | ×          | encode | 转换为 JSON 为 null 时忽略这个属性                  |

**note:**  × 表示无参数

#### 4. Errors

| JSON.Error       | Associated Values                      |
| ---------------- | -------------------------------------- |
| .initalize       | (error: Swift.Error)                   |
| .typeMismatch    | (expected: Any.Type, actual: Any.Type) |
| .encodeToData    | (wrongObject: Any)                     |
| .notExist        | (dict: [String: Any], key: String)     |
| .wrongType       | (subscript: JSON, key: Index)          |
| .outOfBounds     | (arr: [Any], index: Int)               |
| .deserilize      | (from: JSON, to: Any.Type)             |
| .formatter       | (format: String, value: String)        |
| .customTransfrom | (source: Any)                          |

## Extend

### 与 Alamofire 一起使用

```swift
Alamofire.request("https://httpbin.org/get").responseJSON { response in
  let json = JSON(jsonData: response.data)
}
```

### 与 Realm 一起使用

```swift
struct Model: Object, JSONDecodable {
  dynamic var code = 0
  dynamic var name = ""

  init(decode json: JSON) throws {
    code	= try json["code"]<
    name	= try json["name"]<
  }
}
```

## Funtional Programming

`JSON` 类型是一个 Monad 和 Funtor，除了作为 `MutableCollection` 的默认的 `map` 、`flatMap` 方法以外，FxJSON 还实现了如下 `map` 和 `flatMap`：

```swift
public func map<T: JSONDeserializable, U: JSONSerializable>(_ transform: (T) throws -> U) rethrows -> JSON { }
public func flatMap<T: JSONDeserializable>(_ transform: (T) throws -> JSON) rethrows -> JSON { }
```

除此之外，使用 `func <<<T : JSONDeserializable>(lhs: JSON, rhs: JSON.Index)` 和 Curry 、 Applicative 配合 `JSONConvertable` ，还可以这样写（保证多少参数编译器都不会报 `Complicate` ）：

```swift
struct User: JSONConvertable {
  let name: String
  let age: Int?
  let friends: [User]
  
  static func convert(from json: JSON) -> User? {
    return curry(User.init)
      <*> json << "name"
      <*> json << ["others", "age"]
      <*> json << "friends"
  }
}
```

## To do List

- [ ] Document in English
- [ ] Moya support
- [ ] Realm List support
- [ ] Serializer Tool
