# BigOrangeQWQ/fmt

基于 Json 类型的格式化语言库（WIP）
其中格式化表达式参考自 [Python](https://docs.python.org/zh-cn/3/library/string.html#formatstrings)

```moonbit
struct TestObj {
  name : String
  age : Int
} derive(ToJson, FromJson)

///|
test "format with digit" {
  let parts = [FormatPart::Digit(fill='0', width=5), FormatPart::Other]
  fprintln(parts, [1, { name: "Alice", age: 30 }])
}

// future (coming soon)
test "future" {
  fprintln("Hello {:05} {}", [1, { name: "Alice", age: 30 }])
}

```

# Task

- [ ] 支持基础的表达式
- [ ] 支持所有表达式
- [ ] 可通过 format_string 进行解析