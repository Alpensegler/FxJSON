

# Features

- [x] [快速](#它很快)


- [x] [JSON 和自定义数据结构**互相**转化](#FxJSON-能很轻易地将-JSON-和自定义结构互相转化，只需一个方法)


- [x] [自定义转化方式](#4.-TransformType)


- [x] [错误处理](#3.-错误处理)


- [x] [多类型支持](#4.-类型支持)


- [x] [playground 示例](#使用-playground-查看：)


- [x] [与多个主流库一同使用]()
- [x] [支持函数式编程]()


# Overview —— Why FxJSON

#### 它很快

这里用了和  [JASON](https://github.com/delba/JASON) 相同的[Benchmarks]()（改成了 Swift 3 的语法），见 [PerformanceTests](https://github.com/FrainL/FxJSON/blob/master/FxJSONTests/PerformanceTests.swift) 。

|            |         100         |        1000        |       10000        |    Δ    |
| ---------- | :-----------------: | :----------------: | :----------------: | :-----: |
| FxJSON     | 0.002sec(21% STDEV) | 0.017sec(9% STDEV) | 0.170sec(9% STDEV) |    1    |
| SwiftyJSON | 0.007sec(16% STDEV) | 0.075sec(8% STDEV) | 0.678sec(8% STDEV) | 3.5~4.4 |
| JASON      | 0.009sec(10% STDEV) | 0.083sec(3% STDEV) | 0.852sec(6% STDEV) | 4.5~5.0 |

#### 它很优雅

[所有支持的类型]()你都可以通过下面这种方式来从 JSON 转换：

```swift
let json = JSON(jsonData: someDataFromNet) 			// could be Optional
let json = JSON(jsonString: someJSONStringFromNet)	// could be Optional
if let numbers = [Int](json["data", "numbers"]) {
  // do some thing with numbers
}
```

甚至直接从 `Data?` 或 JSON 形式的 `String?` 转换：

```swift
if let dict = try? [String: String](jsonData: someDataFromNet) {
  // do some thing with dict
}
```

或者使用带非常 Swifty 的错误处理方式的 `throws` 转换：

```swift
do {
  let number = try Int(throws: json["code"])
} catch let JSON.Error.notExist(dict: dict, key: key) {
  print(dict, key)
} catch {
  print(error)
}
```

同时，这些支持的结构还能直接转化为 `JSON` 或者 `Data`、JSON 形式的 `String`

```swift
let json = ["key": 123].json
let data = try [123, 456, 789].jsonData()
```

#### 它很全面

使用 FxJSON 你不仅能将 JSON 类型转化为 FxJSON 的支持类型，你还能通过一些 [Protocol]() 来让任何数据结构支持上面的全部功能。

使用  `JSONDecodable` 来使自定义类型能从 JSON 转化：

```swift
struct User: JSONDecodable {
  
  let gender: Gender
  let website: URL
  let signUpTime: Date
  
  enum Gender: Int, JSONTransformable { // RawRepresentable 默认通过 rawValue 支持
    case boy
    case girl
  }
  
  init(decode json: JSON) throws {
    gender      = try json["gender"]<
    website     = try json["website"]<
    signUpTime  = try json["signUpTime"][DateTransform.timeIntervalSince(.year1970)]<
    // 使用 DateTransform 来指定如何转换为 Date
  }
}

let user = try User(throws: json)
```

使用 `JSONConvertable` 来使类类型支持从 JSON 转化：

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

if let color = UIColor(json) {
  //Use color to do something
}
```

使用 `JSONEncodable` 来支持转换为 JSON：

```swift
extension User: JSONEncodeable { } // 默认通过 Mirror 实现

// 或者你也可以自己定义 encode 函数(非必须)
extension User {
  func encode(mapper: JSON.Mapper) {
    mapper["gender"] << gender
    mapper["website"] << website
    mapper["signUpTime"] << signUpTime
  }
}
```

#### 它很好用

使用 `JSONMappable` ，你不用写一个 `map`  函数，不用继承自 `NSObject` ，FxJSON 默认为你支持从 JSON 到该结构（不管是 `Class` 还是 `Struct` ）的转化。

```swift
struct User: JSONMappable { //只需 JSONMappable 实现 init()，默认通过 Mirror 转换
	var userID: Int64!
	var name: String!
	var admin: Bool = false
	var whatsUp: String?
	var website: URL?
	var signUpTime: Date?			//Date 通过 DateTransform.default 转化
    var lastLoginDate = Date()
	var friends: [User]?
}

//或者你也可以用 map 函数自定义转换方式(非必须)
extension User {  
  mutating func map(mapper: JSON.Mapper) {
    admin         >< mapper							// >< 表示忽略该属性
    signUpTime    << mapper["signUpTime"]			// << 表示仅从 JSON 转换到 object
    lastLoginDate >> mapper["lastLoginDate"]		// >> 表示仅从 object 转换到 JSON
    whatsUp       <> mapper[noneNull: "whatsUp"]	// <> 表示和 JSON 互相转换
    //noneNull 参数表示为空时返回，不插入 JSON
  }
}
```

接下来你就可以这样

```swift
if let user = User(json["data", "users", 0]) {
	// do some thing with user
}
```

甚至这样：

```swift
if let users = [User](json["data", "users"]) {
	// do some thing with users
}
```

你就这样来将 user 转换为 json ：

```swift
let json = user.json
```

```swift
let json = users.json
```

自定义 json 数据也很简单：

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

## Install



## Usage



### 1. 使用 playground 查看

1. 打开 FxJSON.workspace
2. 使用 iPhone 5s 以上模拟器 build FxJSON 
3. 在 workspace 中打开 FxJSON.playground

### 2. 处理 JSON 数据

#### 1. 初始化

```swift
let json = JSON(typeThatSupported)
let json = JSON(any: any)					//Any
let json = JSON(jsonData: data)				//Data(could be optional)
let json = JSON(jsonString: jsonString)		//String
```

或者任何自带或使用 protocol 支持的类型都可以直接使用 `some.json` 获取。详见[类型支持](#4.-类型支持)。

#### 2. 获取数据

FxJSON 支持地址式的下标。

```swift
json["data"]["users"]
json["data", "users", 0]

let path: JSON.Index = ["data", "users", 0]
json[path]
json[path, "name"]
```

使用 `Any(json)` 的形式可以获取 optional 数据。

```swift
if let code = Int(json["code"]) {
	// do something here
}
let website = URL(json[path]["website"])
```

使用 `Any(noneNull: json)` 的形式可以获取非 optional 数据。详见[类型支持](#4.-类型支持)。

```swift
let uid = Int(noneNull: json[path]["uid"])
```

还可以使用 `[Any](json)` 或者`[String : Any](json)` 的形式获取数据（同样为optional）。

```swift
let codes = [Int](json)
```

### 3. 错误处理

RxJSON 保证怎么样玩都不会出错，并提供错误处理：

```swift
if let num = Int(json[0]) {
	// do something
} else {
	// do something with error
	json[0].error?.localizedDescription		//"Array[0] failure, its not an array"
	print(json.type)						//"Object\n"
}
```

不管是数组越界，类型转化都有错误处理手段：

```swift
do {
	let num: Int = try json["data"]<
} catch let error as NSError {
	// do something
	error?.localizedDescription		//"Deserialize error, JSON is Object..."
}
```

### 4. For-in

```swift
// If JSON is an object
for (key, v) in json.asDic {
	// do something
}
// If JSON is an array
for v in json.asArray {
	// do something
}
```

### 5. 创造 JSON

FxJSON 能提供目前为止最为便捷的创造 JSON 的方式，使用 Literal：

```swift
let json: JSON = [
	"uid": uid,
	"name": name,
	"admin": admin
]
```

使用操作符 `<<` ：

```swift
var json = JSON {
	code	>> $0["code"]
	user	>> $0["data", "users", 1]
}

json.transfrom {
	userJSON	>> $0[path]
	()			>> $0[noneNull: path, "signature"]
	website		>> $0[path, "website"]
	dateOne		>> $0[path, "signUpTime"][DateTF()]
}
```

### 3. 使用协议

#### 1. JSONDecodable 

#### 2. JSONEncodable

#### 3. JSONMappable

## 类型支持

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

## Extend

### 与 Alamofire 一起使用

```swift
Alamofire.request(.GET, url).validate().responseJSON { response in
  switch response.result {
  case .Success:
    let json = JSON(jsonData: response.result.value)
    print("JSON: \(json)")
  case .Failure(let error):
    print(error)
  }
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



```swift
struct User: JSONConvertable {
	let name: String
	let age: Int?
	let friends: [User]
	
	static func convert(from json: JSON) -> User? {
		return curry(User.init)
			<*>	json << "name"
			<*> json << ["others", "age"]
			<*> json << "friends"
	}
}
```

## To do List

