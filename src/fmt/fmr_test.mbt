///|
struct TestObj {
  name : String
  age : Int
} derive(ToJson, FromJson)

///|
test "example/1" {
  fprintln("Hello {:05} {}", [1, { name: "Alice", age: 30 }])
}

///|
test "example/2" {
  let parts = "{0} {1} {{not things}} {1} {2:.2f}"
  fprintln(parts, ["hello", "world", 42])
  // Expected output: "Hello World 42"
}

///|
test "example/3" {
  let parts = "{} {} {}"
  fprintln(parts, ["hello", "world", 42])
}
