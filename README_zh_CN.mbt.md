# BigOrangeQWQ/fmt

本库提供了类似 Python `str.format` 的强大格式化能力，支持多类型、多样式的字符串格式化，底层浮点数转字符串算法基于 [Moonbit Core Ryu](https://github.com/moonbitlang/core/tree/main/double/internal/ryu)。

### 多参数与花括号转义

```moonbit
test {
  let parts = "{0} {1} {{not things}} {1} {2:.2f}"
  @fmt.fprintln(parts, ["hello", "world", 42])
}
// 输出: hello world {not things} world 42.00
```

### 顺序参数

```moonbit
test {
  @fmt.fprintln("{} {} {}", ["hello", "world", 42])
}
// 输出: hello world 42
```

### 进制与前缀格式化

```moonbit
test {
  @json.inspect(@fmt.fstring("{:o}", [8]), content="10")
  @json.inspect(@fmt.fstring("{:#o}", [8]), content="0o10")
  @json.inspect(@fmt.fstring("{:b}", [16]), content="10000")
}
```

### 对齐与填充

```moonbit
test {
  @json.inspect(@fmt.fstring("{:>>30}", ["test"]), content=(">>>>>>>>>>>>>>>>>>>>>>>>>>test"))
  @json.inspect(@fmt.fstring("{:<<30}", ["test"]), content=("test<<<<<<<<<<<<<<<<<<<<<<<<<<"))
  @json.inspect(@fmt.fstring("{:^^30}", ["test"]), content=("^^^^^^^^^^^^^test^^^^^^^^^^^^^"))
}
```

### 分组分隔符

```moonbit
test {
  @json.inspect(@fmt.fstring("{:_d}", [4285565, 59]), content="428_556_5")
  @json.inspect(@fmt.fstring("{:,d}", [4285565, 3]), content="428,556,5")
  @json.inspect(@fmt.fstring("{:#_b}", [4285565, 3]), content="0b1000_0010_1100_1000_1111_101")
}
```

### 实数精度

```moonbit
test {
  @json.inspect(@fmt.fstring("{:.5E}", [42.5]), content="4.25000E+01")
  @json.inspect(@fmt.fstring("{:.10e}", [4464252.51334]), content="4.4642525133e+06")
  @json.inspect(@fmt.fstring("{:.17e}", [4464252.51334]), content="4.46425251334000006e+06")
}
```

### 百分比/科学计数法

-   数字类型每隔 3 位加分隔符，其它进制每隔 4 位加分隔符，逗号仅支持数字类型。

## 格式化语法说明

| 语法示例         | 说明                          | 输出示例                             |
| ---------------- | ----------------------------- | ------------------------------------ |
| `{}`             | 自动顺序参数                  | `hello`（参数为 "hello"）            |
| `{0}`            | 指定位置参数                  | `world`（参数为 ["hello", "world"]） |
| `{{` / `}}`      | 输出单个 `{` 或 `}`           | `{` 或 `}`                           |
| `{:05}`          | 宽度 5，左侧补 0              | `00042`                              |
| `{:>10}`         | 宽度 10，右对齐               | `     test`                          |
| `{:<10}`         | 宽度 10，左对齐               | `test     `                          |
| `{:^10}`         | 宽度 10，居中对齐             | `test`                               |
| `{:*^10}`        | 居中对齐，填充字符为`*`       | `***test***`                         |
| `{:b}` / `{:#b}` | 二进制输出/带前缀             | `10000` / `0b10000`                  |
| `{:o}` / `{:#o}` | 八进制输出/带前缀             | `10` / `0o10`                        |
| `{:x}` / `{:#x}` | 十六进制小写/带前缀           | `ff` / `0xff`                        |
| `{:X}` / `{:#X}` | 十六进制大写/带前缀           | `FF` / `0XFF`                        |
| `{:d}`           | 十进制整数                    | `42`                                 |
| `{:05d}`         | 宽度 5，左侧补 0 的十进制整数 | `00042`                              |
| `{:.2f}`         | 浮点数保留 2 位小数           | `3.14`（参数为 3.1415）              |
| `{:e}` / `{:E}`  | 科学计数法（小写/大写 E）     | `4.25e+1` / `4.25E+1`（参数为 42.5） |
| `{:%}`           | 百分号格式，自动乘 100        | `4250.00%`（参数为 42.5）            |
| `{:>>10}`        | 宽度 10，右对齐，填充`>`      | `>>>>>>>test`                        |
| `{:_d}`          | 十进制分组下划线              | `428_556_5`                          |
| `{:,d}`          | 十进制分组逗号                | `428,556,5`                          |
| `{:#_b}`         | 进制分组下划线带前缀          | `0b1000_0010_1100_1000_1111_101`     |

> 注：分组分隔符逗号（,）仅支持十进制数字类型，其余二进制、八进制、十六进制仅支持下划线（\_）分隔。

# Thanks

浮点数转换字符串的代码来自于标准库 [Core](https://github.com/moonbitlang/core/tree/main/double/internal/ryu)
