struct TestObj {
  name : String
  age : Int
} derive(ToJson, FromJson)

///|
test "format example" {
  let obj: TestObj =  { name: "Alice", age: 30 }
  fprintln("Hello {:*<5} {}", [1, obj.to_json()])
}

///|
test "fprintln" {
  let parts = "{0} {1} {2:.2f}"
  fprintln(parts, ["hello", "world", 42])
  // Expected output: "Hello World 42"
}

///|
test "fprintln" {
  let parts = "{} {} {}"
  fprintln(parts, ["hello", "world", 42])
}



