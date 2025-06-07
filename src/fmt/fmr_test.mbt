///|
struct TestObj {
  name : String
  age : Int
} derive(ToJson, FromJson)

///qqc|
test "example/1" {
  fprintln("Hello {:05} {}", [1, { name: "Alice", age: 30 }])
  
  inspect(
    fstring("Hello {:05} {}", [1, { name: "Alice", age: 30 }]),
    content=
      #|Hello 00001 Object({"name": String("Alice"), "age": Number(30)})
    ,
  )
}

///|
test "example/2" {
  let parts = "{0} {1} {{not things}} {1} {2:.2f}"
  fprintln(parts, ["hello", "world", 42])
  inspect(
    fstring(parts, ["hello", "world", 42]),
    content= "hello world {not things} world 42.00"
  )
}

///|
test "example/3" {
  fprintln("{} {} {}", ["hello", "world", 42])
  inspect(
    fstring("{} {} {}", ["hello", "world", 42]),
    content= "hello world 42"
  )
}

test "Oct" {
  inspect(fstring("{:o}", [8]), content="10")
  inspect(fstring("{:#o}", [8]), content="0o10")
}