import PlaygroundSupport
import Foundation
import FxJSON

PlaygroundPage.current.needsIndefiniteExecution = true

let request = URLRequest(url: URL(string: "https://h.nimingban.com/Api/getForumList")!)

let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
    let json = JSON(jsonData: data)
    print(json)
    PlaygroundPage.current.finishExecution()
}

task.resume()
