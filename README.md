# BigOrangeQWQ/fmt

基于 Json 类型的格式化语言库（WIP）
其中格式化表达式参考自 [Python](https://docs.python.org/zh-cn/3/library/string.html#formatstrings)

```moonbit
struct TestObj {
  name : String
  age : Int
} derive(ToJson, FromJson)

///|
test "example/1" {
  fprintln("Hello {:05} {}", [1, { name: "Alice", age: 30 }])
  // Hello 00001 Object({"name": String("Alice"), "age": Number(30)})
}

///|
test "example/2" {
  let parts = "{0} {1} {{not things}} {1} {2:.2f}"
  fprintln(parts, ["hello", "world", 42])
  // hello world {not things} world 42.00
}

///|
test "example/3" {
  let parts = "{} {} {}"
  fprintln(parts, ["hello", "world", 42])
  //hello world 42
  inspect(
    fstring("{} {} {}", ["hello", "world", 42]),
    content= "hello world 42"
  )
}
```


# TODO

- [x] 支持基础的表达式
- [ ] 支持所有表达式
- [ ] 可通过 format_string 进行解析


# Thanks

处理浮点数字符串相关 [Core](https://github.com/moonbitlang/core/blob/03c9be796626e5fced57fdbfed4f9ad4eee16e3f/double/internal/ryu)