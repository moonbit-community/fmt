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
      #|Hello 00001 {"name": String("Alice"), "age": Number(30)}

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

test "example/4" {
  inspect(fstring("{:o}", [8]), content="10")
  inspect(fstring("{:#o}", [8]), content="0o10")
  inspect(fstring("{:b}", [16]), content="10000")
  inspect(fstring("{:#b}", [16]), content="0b10000")
  inspect(fstring("{:x}", [255]), content="ff")
  inspect(fstring("{:#x}", [255]), content="0xff")
  inspect(fstring("{:X}", [255]), content="FF")
  inspect(fstring("{:#X}", [255]), content="0XFF")
}

test "example/5" {
  inspect(fstring("{:>>30}", ["test"]), content=">>>>>>>>>>>>>>>>>>>>>>test")
  inspect(fstring("{:<<30}", ["test"]), content="test<<<<<<<<<<<<<<<<<<<<<<")
  inspect(fstring("{:^^30}", ["test"]), content="^^^^^^^^^^^test^^^^^^^^^^^")
}

// 支持数字类型、二进制、八进制、十六进制的分隔符格式化
// 数字类型每隔3位加一个分隔符，其它类型每隔4位加一个分隔符，逗号仅支持数字类型
test "example/6" {
  inspect(fstring("{:_d}", [4285565, 59]), content="428_556_5")
  inspect(fstring("{:,d}", [4285565, 3]), content="428,556,5")
  inspect(fstring("{:#_b}", [4285565, 3]), content="0b1000_0010_1100_1000_1111_101")
}