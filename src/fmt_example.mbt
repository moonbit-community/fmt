///|
priv struct TestObj {
  name : String
  age : Int
} derive(ToJson, FromJson)

///|qqc|
test "example/1" {
  jprintln("Hello {:05} {}", [1, { name: "Alice", age: 30 }])
  inspect(
    jstring("Hello {:05} {}", [1, { name: "Alice", age: 30 }]),
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
    content="hello world {not things} world 42.00",
  )
}

///|
test "example/3" {
  fprintln("{} {} {}", ["hello", "world", 42])
  inspect(fstring("{} {} {}", ["hello", "world", 42]), content="hello world 42")
}

///|
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

///|
test "example/5" {
  inspect(fstring("{:>>30}", ["test"]), content=">>>>>>>>>>>>>>>>>>>>>>test")
  inspect(fstring("{:<<30}", ["test"]), content="test<<<<<<<<<<<<<<<<<<<<<<")
  inspect(fstring("{:^^30}", ["test"]), content="^^^^^^^^^^^test^^^^^^^^^^^")
}

///|
test "example/6" {
  inspect(fstring("{:_d}", [4285565, 59]), content="428_556_5")
  inspect(fstring("{:,d}", [4285565, 3]), content="428,556,5")
  inspect(
    fstring("{:#_b}", [4285565, 3]),
    content="0b1000_0010_1100_1000_1111_101",
  )
}

///|
test "example/7" {
  inspect(fstring("{:d}", [42.5]), content="42")
}

///|
test "example/8" {
  inspect(fstring("{:e}", [42.5]), content="4.250000e+01")
  inspect(fstring("{:E}", [42.5]), content="4.250000E+01")
  inspect(fstring("{:%}", [42.5]), content="4250.00%")
}

///|
test "example/9" {
  inspect(fstring("{:.5E}", [42.5]), content="4.25000E+01")
  inspect(fstring("{:.10e}", [4464252.51334]), content="4.4642525133e+06")
  inspect(
    fstring("{:.17e}", [4464252.51334]),
    content="4.46425251334000006e+06",
  )
}

///|
test "example/10" {
  inspect(fstring("{}", [-114514]), content="-114514")
}

test "panic example/11" {
  inspect(fstring("{:#0x8}", [1]), content="0x000001")
}

test "example/12" {
  inspect(fstring("{:#08x}", [1]), content="0x000001")
}


test "example/12" {
  inspect(fstring("{:#09x}", [15]), content="0x000000f")
}