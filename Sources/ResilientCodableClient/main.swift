import ResilientCodable
import Foundation

let json = """
{
    "foo" = 1
}
"""

@ResilientCodable
struct Foo: Codable {
    var foo: Int = 0
    var bar: String = "bar"
}

let decoder = JSONDecoder()
let data = json.data(using: .utf8)!
do {
    let foo = try decoder.decode(Foo.self, from: data)
    print("foo is \(foo.foo) and bar is \(foo.bar)")
} catch {
    print(error.localizedDescription)
}
