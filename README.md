# BigOrangeQWQ/fmt

基于 Json 类型的格式化语言库（WIP）
其中格式化表达式参考自 [Python](https://docs.python.org/zh-cn/3/library/string.html#formatstrings)

```moonbit
struct TestObj {
  name : String
  age : Int
} derive(ToJson, FromJson)

///|
test "format example" {
  fprintln("Hello {:05} {}", [1, { name: "Alice", age: 30 }])
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

```

# Task 任务

- [ ] 支持基础的表达式
- [ ] 支持所有表达式
- [ ] 可通过 format_string 进行解析


# Thanks 致谢

处理浮点数相关的字符串 [Core](https://github.com/moonbitlang/core/blob/03c9be796626e5fced57fdbfed4f9ad4eee16e3f/double/internal/ryu)