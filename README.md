

# Features

- [x] [快速](#它很快)


- [x] [JSON 和自定义数据结构**互相**转化](#FxJSON-能很轻易地将-JSON-和自定义结构互相转化，只需一个方法)


- [x] [自定义转化方式](#4.-TransformType)


- [x] [错误处理](#3.-错误处理)


- [x] [多类型支持](#4.-类型支持)


- [x] [playground 示例](#使用-playground-查看：)


- [x] [与多个主流库一同使用]()


# Why FxJSON

你大概知道 Swift 中要使用 `[String: Any]` 并不太方便。

你也大概听说了 [SwiftJSON](https://github.com/SwiftyJSON/SwiftyJSON) [Alamofire](https://github.com/Alamofire/Alamofire) [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper) 这些非常棒非常好用的开源库，并从中获取了更高的效率。

为什么不试试更进一步提高效率呢？试试 FxJSON 吧。

#### 它很快

这里用了和  [JASON](https://github.com/delba/JASON) 相同的[测试]()（改成了 Swift 3 的语法），见 [PerformanceTests](https://github.com/FrainL/FxJSON/blob/master/FxJSONTests/PerformanceTests.swift) 。

|            |         100         |        1000        |       10000        |    Δ    |
| ---------- | :-----------------: | :----------------: | :----------------: | :-----: |
| FxJSON     | 0.002sec(21% STDEV) | 0.017sec(9% STDEV) | 0.170sec(9% STDEV) |    1    |
| SwiftyJSON | 0.007sec(16% STDEV) | 0.075sec(8% STDEV) | 0.678sec(8% STDEV) | 3.5~4.4 |
| JASON      | 0.009sec(10% STDEV) | 0.083sec(3% STDEV) | 0.852sec(6% STDEV) | 4.5~5.0 |

#### 它很优雅

所有支持的类你都可以通过下面这种方式来从 JSON 转换：

```swift
let json = JSON(data: someDataFromNet)
if let number = Int(json["data", "number"]) {
  // do some thing with number
}
```

甚至直接从 `Data?` 或 json 形式的 `String` 转换：

```swift
if let dict = [String: String](data: someDataFromNet) {
  // do some thing with dict
}
```



#### 它很全面



#### 它好用

FxJSON 能很轻易地将 JSON 和自定义结构互相转化。当我说很轻易的时候，是真的很轻易。你甚至连

```swift
struct User: JSONMappable {
	var userID: Int64!
	var name: String!
	var admin: Bool = false
	var whatsUp: String?
	var website: URL?				//URL 自动转化
	var signUpTime: Date?			//Date 通过 DateTransform 转化
	var friends: [User]?			//自己的数据结构也可以转化
}
```

只需要继承 JSONMapable 协议，你就可以这样来转换 JSON 成 User：

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

同时还可以这样来将 user 转换为 json ：

```swift
let json = user.json
```

```swift
let json = users.json
```

自定义 json 数据也很简单：

```swift
let json: JSON = ["code": 0, "data": ["users": users]]
```

甚至还能这样：

```swift
let json = JSON {
	0		>> $0["code"]
	users	>> $0["data", "users"]
}
```

怎么样，够不够高效率？

# 使用

#### 使用 playground 查看：

1. 打开 FxJSON.workspace
2. 使用 iPhone 5s 以上模拟器 build FxJSON 
3. 在 workspace 中打开 FxJSON.playground

## 2. 处理 JSON 数据

### 1. 初始化

```swift
let json = JSON(data)	//NSData(could be optional)
```

```swift
let json = JSON(anyObject)	//AnyObject(could be optional)
```

```swift
let json = JSON(jsonString: jsonString)		//String
```

或者任何实现了 `JSONEncodable` 的类型都可以直接使用 `some.json` 获取。详见[类型支持](#4.-类型支持)。



### 2. 获取数据

RxJSON 支持地址式的下标。

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
let website = NSURL(json[path]["website"])
```

使用 `Any(value: json)` 的形式可以获取非 optional 数据。详见[类型支持](#4.-类型支持)。

```swift
let uid = Int(value: json[path]["uid"])
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

使用操作符 `>>` ：

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



## 3. 使用协议

### 1. JSONMappable

### 2. JSONDecodable

### 3. JSONEncodable

### 4. TransformType

## 4. 类型支持

- `Int`
- `Int64`
- `Bool`
- `Double`
- `Float`
- `String`
- `NSDate`
- `NSURL`
- `RawRepresentable` (enum)
- `T` (遵循协议的自定义类)
- `[T]`
- `[[T]]`

# 与其他库一同使用

## 与 Alamofire 一起使用

```swift
Alamofire.request(.GET, url).validate().responseJSON { response in
    switch response.result {
    case .Success:
        let json = JSON(response.result.value)
        print("JSON: \(json)")
    case .Failure(let error):
        print(error)
    }
}
```

## 与 Realm 一起使用

```swift
struct Model: Object, JSONDecodable {
	dynamic var code = 0
	dynamic var name = ""

	init(json: JSON) throws {
		code	= try json["code"]<
		name	= try json["name"]<
	}
}
```

## 与函数式库一起使用

```swift
struct User: JSONDeserializable {
	let name: String
	let age: Int?
	
	static func convert(from json: JSON) -> User? {
		return curry(User.init)
			<*>	json["name"]<
			<*> json["age"]<
	}
}
```

