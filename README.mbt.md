[中文文档 (Chinese README)](./README_zh_CN.md)

# BigOrangeQWQ/fmt

This library provides powerful formatting capabilities similar to Python's `str.format`, supporting multi-type and multi-style string formatting. The underlying float-to-string algorithm is based on [Moonbit Core Ryu](https://github.com/moonbitlang/core/tree/main/double/internal/ryu).

### Multiple arguments and brace escaping

```moonbit
test {
    let parts = "{0} {1} {{not things}} {1} {2:.2f}"
    @fmt.fprintln(parts, ["hello", "world", 42])
}
// Output: hello world {not things} world 42.00
```

### Positional arguments

```moonbit
test {
    @fmt.fprintln("{} {} {}", ["hello", "world", 42])
}
// Output: hello world 42
```

### Radix and prefix formatting

```moonbit
test {
    @json.inspect(@fmt.fstring("{:o}", [8]), content="10")
    @json.inspect(@fmt.fstring("{:#o}", [8]), content="0o10")
    @json.inspect(@fmt.fstring("{:b}", [16]), content="10000")
}
```

### Alignment and padding

```moonbit
test {
    @json.inspect(@fmt.fstring("{:>>30}", ["test"]), content=(">>>>>>>>>>>>>>>>>>>>>>>>>>test"))
    @json.inspect(@fmt.fstring("{:<<30}", ["test"]), content=("test<<<<<<<<<<<<<<<<<<<<<<<<<<"))
    @json.inspect(@fmt.fstring("{:^^30}", ["test"]), content=("^^^^^^^^^^^^^test^^^^^^^^^^^^^"))
}
```

### Grouping separators

```moonbit
test {
    @json.inspect(@fmt.fstring("{:_d}", [4285565, 59]), content="428_556_5")
    @json.inspect(@fmt.fstring("{:,d}", [4285565, 3]), content="428,556,5")
    @json.inspect(@fmt.fstring("{:#_b}", [4285565, 3]), content="0b1000_0010_1100_1000_1111_101")
}
```

### Precision

```moonbit
test {
    @json.inspect(@fmt.fstring("{:.5E}", [42.5]), content="4.25000E+01")
    @json.inspect(@fmt.fstring("{:.10e}", [4464252.51334]), content="4.4642525133e+06")
    @json.inspect(@fmt.fstring("{:.17e}", [4464252.51334]), content="4.46425251334000006e+06")
}
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
