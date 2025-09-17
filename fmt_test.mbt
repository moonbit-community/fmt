///|
test "width 0, width 1, width large" {
  @json.inspect(fstring("{:0}", [42]), content="42")
  @json.inspect(fstring("{:1}", [42]), content="42")
  @json.inspect(fstring("{:10}", [42]), content="        42")
  @json.inspect(
    fstring("{:100}", [42]),
    content="                                                                                                  42",
  )
}

///|
test "fill with special char" {
  @json.inspect(fstring("{:*^10}", ["abc"]), content="***abc****")
  @json.inspect(
    fstring("{:😀^8}", ["hi"]),
    content="😀😀😀hi😀😀😀",
  )
}

///|
test "precision 0 and large" {
  @json.inspect(fstring("{:.0f}", [3.1415]), content="3")
  @json.inspect(fstring("{:.10f}", [3.1415]), content="3.1415000000")
}

///|
test "negative, zero, empty, long string" {
  @json.inspect(fstring("{}", [-42]), content="-42")
  @json.inspect(fstring("{}", [0]), content="0")
  @json.inspect(fstring("{}", [""]), content="")
  @json.inspect(
    fstring("{}", ["a".repeat(100)]),
    content="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  )
}

///|
test "grouping and base mix" {
  @json.inspect(fstring("{:_d}", [1234567890]), content="123_456_789_0")
  @json.inspect(fstring("{:,d}", [1234567890]), content="123,456,789,0")
  @json.inspect(fstring("{:#_b}", [255]), content="0b1111_1111")
  @json.inspect(fstring("{:#_x}", [65535]), content="0xffff")
}

///|
test "escaped braces" {
  @json.inspect(fstring("{{}}", []), content="{}")
  @json.inspect(fstring("{{{:d}}}", [42]), content="{42}")
}

///|
test "multi-arg and mixed" {
  @json.inspect(
    fstring("{}-{:*^6}-{:>4}", ["a", "b", "c"]),
    content="a-**b***-   c",
  )
  assert_eq(
    fstring("{}-{:*^6}-{:<4}", ["a", "b", "c"]), // String align default is left
    fstring("{}-{:*^6}-{:4}", ["a", "b", "c", ]),
  )
  @json.inspect(fstring("{0} {1} {0}", ["x", "y"]), content="x y x")
}

///|
test "percent and scientific" {
  @json.inspect(fstring("{:%}", [0.1234]), content="12.34%")
  @json.inspect(fstring("{:.2E}", [1234.5]), content="1.23E+03")
}

///|
test "fail align_sharp" {
  @json.inspect(
    fstring("{:020x}", ["dwafafawf"]),
    content="00000000000dwafafawf",
  )
}


test "json" {
  @json.inspect(
    fstring("{0} {1} {{not things}} {1} {2:.2f}", ["hello", "world", 42]),
    content="hello world {not things} world 42.00",
  )
}