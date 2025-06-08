[中文文档 (Chinese README)](./README_zh_CN.md)

# BigOrangeQWQ/fmt

This library provides powerful formatting capabilities similar to Python's `str.format`, supporting multi-type and multi-style string formatting. The underlying float-to-string algorithm is based on [Moonbit Core Ryu](https://github.com/moonbitlang/core/tree/main/double/internal/ryu).

### Struct to Json automatically

```moonbit
struct TestObj {
  name : String
  age : Int
} derive(ToJson)

fprintln("Hello {:05} {}", [1, { name: "Alice", age: 30 }])
// Output: Hello 00001 {"name": String("Alice"), "age": Number(30)}
```

### Multiple arguments and brace escaping

```moonbit
let parts = "{0} {1} {{not things}} {1} {2:.2f}"
fprintln(parts, ["hello", "world", 42])
// Output: hello world {not things} world 42.00
```

### Positional arguments

```moonbit
fprintln("{} {} {}", ["hello", "world", 42])
// Output: hello world 42
```

### Radix and prefix formatting

```moonbit
fstring("{:o}", [8])      // "10"
fstring("{:#o}", [8])     // "0o10"
fstring("{:b}", [16])     // "10000"
```

### Alignment and padding

```moonbit
fstring("{:>>30}", ["test"]) // ">>>>>>>>>>>>>>>>>>>>>>test"
fstring("{:<<30}", ["test"]) // "test<<<<<<<<<<<<<<<<<<<<<<"
fstring("{:^^30}", ["test"]) // "^^^^^^^^^^^test^^^^^^^^^^^"
```

### Grouping separators

```moonbit
fstring("{:_d}", [4285565, 59])         // "428_556_5"
fstring("{:,d}", [4285565, 3])          // "428,556,5"
fstring("{:#_b}", [4285565, 3])         // "0b1000_0010_1100_1000_1111_101"
```

-   For decimal types, a separator is added every 3 digits; for other bases, every 4 digits. Comma (`,`) is only supported for decimal types.

## Formatting Syntax Reference

| Syntax Example   | Description                           | Output Example                         |
| ---------------- | ------------------------------------- | -------------------------------------- |
| `{}`             | Automatic sequential argument         | `hello` (argument: "hello")            |
| `{0}`            | Positional argument                   | `world` (argument: ["hello", "world"]) |
| `{{` / `}}`      | Output a single `{` or `}`            | `{` or `}`                             |
| `{:05}`          | Width 5, left pad with 0              | `00042`                                |
| `{:>10}`         | Width 10, right align                 | `     test`                            |
| `{:<10}`         | Width 10, left align                  | `test     `                            |
| `{:^10}`         | Width 10, center align                | `test`                                 |
| `{:*^10}`        | Center align, fill with `*`           | `***test***`                           |
| `{:b}` / `{:#b}` | Binary / with prefix                  | `10000` / `0b10000`                    |
| `{:o}` / `{:#o}` | Octal / with prefix                   | `10` / `0o10`                          |
| `{:x}` / `{:#x}` | Hex lower / with prefix               | `ff` / `0xff`                          |
| `{:X}` / `{:#X}` | Hex upper / with prefix               | `FF` / `0XFF`                          |
| `{:d}`           | Decimal integer                       | `42`                                   |
| `{:05d}`         | Width 5, left pad 0 decimal           | `00042`                                |
| `{:e}` / `{:E}`  | Scientific notation (lower/upper E)   | `4.25e+1` / `4.25E+1` (argument: 42.5) |
| `{:.2f}`         | Float with 2 decimal places           | `3.14` (argument: 3.1415)              |
| `{:%}`           | Percent format, auto multiply by 100  | `4250.00%` (argument: 42.5)            |
| `{:>>10}`        | Width 10, right align, fill `>`       | `>>>>>>>test`                          |
| `{:_d}`          | Decimal grouped with underscore       | `428_556_5`                            |
| `{:,d}`          | Decimal grouped with comma            | `428,556,5`                            |
| `{:#_b}`         | Base grouped with underscore & prefix | `0b1000_0010_1100_1000_1111_101`       |

> Note: Comma (`,`) as a grouping separator is only supported for decimal types; binary, octal, and hexadecimal only support underscore (`_`) as a separator.

# Thanks

The float-to-string conversion code is from the standard library [Core](https://github.com/moonbitlang/core/tree/main/double/internal/ryu)
