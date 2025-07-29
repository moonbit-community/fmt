///|
// Tests for Formatter trait implementations and custom formatting

///|
test "formatter/basic_types" {
  // Test all basic types that implement Formatter
  
  // String formatting
  inspect(fstring("{}", ["hello"]), content="hello")
  inspect(fstring("{:>10}", ["test"]), content="      test")
  inspect(fstring("{:<10}", ["test"]), content="test      ")
  inspect(fstring("{:^10}", ["test"]), content="   test   ")
  
  // Character formatting
  inspect(fstring("{}", ['A']), content="A")
  inspect(fstring("{:>5}", ['B']), content="    B")
  inspect(fstring("{:*<5}", ['C']), content="C****")
  
  // Boolean formatting
  inspect(fstring("{}", [true]), content="true")
  inspect(fstring("{}", [false]), content="false")
  inspect(fstring("{:>8}", [true]), content="    true")
  inspect(fstring("{:>8}", [false]), content="   false")
}

///|
test "formatter/integer_types" {
  // Test different integer types
  let int_val = 42
  let int64_val = 42L
  let int16_val : Int16= 42
  let uint_val = 42U
  let uint64_val = 42UL
  let uint16_val : UInt16 = 42
  
  // Basic formatting should work for all
  inspect(fstring("{}", [int_val]), content="42")
  inspect(fstring("{}", [int64_val]), content="42")
  inspect(fstring("{}", [int16_val]), content="42")
  inspect(fstring("{}", [uint_val]), content="42")
  inspect(fstring("{}", [uint64_val]), content="42")
  inspect(fstring("{}", [uint16_val]), content="42")
  
  // Width formatting should work for all
  inspect(fstring("{:5}", [int_val]), content="42   ")
  inspect(fstring("{:5}", [int64_val]), content="42   ")
  inspect(fstring("{:5}", [int16_val]), content="42   ")
  inspect(fstring("{:5}", [uint_val]), content="42   ")
  inspect(fstring("{:5}", [uint64_val]), content="42   ")
  inspect(fstring("{:5}", [uint16_val]), content="42   ")
  
  // Hex formatting should work for all integer types
  inspect(fstring("{:x}", [int_val]), content="2a")
  inspect(fstring("{:x}", [int64_val]), content="2a")
  inspect(fstring("{:x}", [int16_val]), content="2a")
  inspect(fstring("{:x}", [uint_val]), content="2a")
  inspect(fstring("{:x}", [uint64_val]), content="2a")
  inspect(fstring("{:x}", [uint16_val]), content="2a")
}

///|
test "formatter/float_types" {
  // Test Float and Double types
  let float_val : Float = 3.14
  let double_val = 3.14
  
  // Basic formatting
  inspect(fstring("{}", [float_val]), content="3.14")
  inspect(fstring("{}", [double_val]), content="3.14")
  
  // Precision formatting
  inspect(fstring("{:.1f}", [float_val]), content="3.1")
  inspect(fstring("{:.1f}", [double_val]), content="3.1")
  inspect(fstring("{:.3f}", [float_val]), content="3.140")
  inspect(fstring("{:.3f}", [double_val]), content="3.140")
  
  // Scientific notation
  inspect(fstring("{:e}", [float_val]), content="3.140000e+00")
  inspect(fstring("{:e}", [double_val]), content="3.140000e+00")
  inspect(fstring("{:E}", [float_val]), content="3.140000E+00")
  inspect(fstring("{:E}", [double_val]), content="3.140000E+00")
  
  // Percentage
  inspect(fstring("{:%}", [float_val]), content="314.00%")
  inspect(fstring("{:%}", [double_val]), content="314.00%")
}

///|
test "formatter/numeric_edge_cases" {
  // Test edge cases for numeric formatting
  
  // Zero values
  inspect(fstring("{:d}", [0]), content="0")
  inspect(fstring("{:b}", [0]), content="0")
  inspect(fstring("{:o}", [0]), content="0")
  inspect(fstring("{:x}", [0]), content="0")
  inspect(fstring("{:f}", [0.0]), content="0")
  
  // Large values
  inspect(fstring("{:d}", [2147483647]), content="2147483647") // Max 32-bit int
  inspect(fstring("{:x}", [2147483647]), content="7fffffff")
  
  // Small decimal values
  inspect(fstring("{:f}", [0.001]), content="0.001")
  inspect(fstring("{:.5f}", [0.00001]), content="0.00001")
  
  // Values that require rounding
  inspect(fstring("{:.2f}", [3.999]), content="4.00")
  inspect(fstring("{:.1f}", [2.95]), content="3.0")
}

///|
test "formatter/alignment_with_numbers" {
  // Test alignment specifically with numeric types
  let num = 123
  let float_num = 12.34
  
  // Right alignment (default for numbers typically)
  inspect(fstring("{:>8}", [num]), content="     123")
  inspect(fstring("{:>8}", [float_num]), content="   12.34")
  
  // Left alignment
  inspect(fstring("{:<8}", [num]), content="123     ")
  inspect(fstring("{:<8}", [float_num]), content="12.34   ")
  
  // Center alignment
  inspect(fstring("{:^8}", [num]), content="  123   ")
  inspect(fstring("{:^8}", [float_num]), content=" 12.34  ")
  
  // Custom fill with numbers
  inspect(fstring("{:0>8}", [num]), content="00000123")
  inspect(fstring("{:*>8}", [float_num]), content="***12.34")
}

///|
test "formatter/zero_padding_behavior" {
  // Test zero padding with different number types
  inspect(fstring("{:05d}", [123]), content="00123")
  inspect(fstring("{:05d}", [-123]), content="-0123")
  inspect(fstring("{:08x}", [255]), content="000000ff")
  inspect(fstring("{:08b}", [15]), content="00001111")
  inspect(fstring("{:08o}", [64]), content="00000100")
  
  // Zero padding with width larger than needed
  inspect(fstring("{:010d}", [42]), content="0000000042")
  
  // Zero padding combined with prefix
  inspect(fstring("{:#08x}", [255]), content="0x0000ff")
  inspect(fstring("{:#08b}", [15]), content="0b001111")
  inspect(fstring("{:#08o}", [64]), content="0o000100")
}

///|
test "formatter/prefix_behavior" {
  // Test sharp (#) prefix behavior
  
  // Binary prefix
  inspect(fstring("{:b}", [15]), content="1111")
  inspect(fstring("{:#b}", [15]), content="0b1111")
  inspect(fstring("{:#10b}", [15]), content="0b1111    ")
  
  // Octal prefix
  inspect(fstring("{:o}", [64]), content="100")
  inspect(fstring("{:#o}", [64]), content="0o100")
  inspect(fstring("{:#6o}", [64]), content="0o100 ")
  
  // Hexadecimal prefix
  inspect(fstring("{:x}", [255]), content="ff")
  inspect(fstring("{:#x}", [255]), content="0xff")
  inspect(fstring("{:X}", [255]), content="FF")
  inspect(fstring("{:#X}", [255]), content="0XFF")
  inspect(fstring("{:#6x}", [255]), content="0xff  ")
  inspect(fstring("{:#6X}", [255]), content="0XFF  ")
}

///|
test "formatter/grouping_combinations" {
  // Test digit grouping with various format options
  
  // Decimal grouping
  inspect(fstring("{:,d}", [1234567]), content="123,456,7") // Groups every 3 digits
  inspect(fstring("{:_d}", [1234567]), content="123_456_7")
  inspect(fstring("{:10,d}", [1234567]), content="123,456,7 ") // With width
  inspect(fstring("{:>10,d}", [1234567]), content=" 123,456,7") // With alignment
  
  // Hex grouping (underscore only)
  inspect(fstring("{:_x}", [0xABCDEF]), content="abc_def") // Groups every 4 digits for hex
  inspect(fstring("{:#_x}", [0xABCDEF]), content="0xabc_def")
  
  // Binary grouping (underscore only)  
  inspect(fstring("{:_b}", [0b11110000]), content="1111_0000")
  inspect(fstring("{:#_b}", [0b11110000]), content="0b1111_0000")
  
  // Octal grouping (underscore only)
  inspect(fstring("{:_o}", [0o1234567]), content="123_456_7")
  inspect(fstring("{:#_o}", [0o1234567]), content="0o123_456_7")
}

///|
test "formatter/complex_format_specs" {
  // Test complex combinations of format specifiers
  
  // Prefix + zero padding + width
  inspect(fstring("{:#08x}", [255]), content="0x0000ff")
  inspect(fstring("{:#08b}", [15]), content="0b001111")
  
  // Alignment + custom fill + width + type
  inspect(fstring("{:*>10x}", [255]), content="********ff")
  inspect(fstring("{:->10b}", [15]), content="------1111")
  
  // Grouping + prefix + width
  inspect(fstring("{:#10_x}", [0xABCDEF]), content="0xabc_def ")
  inspect(fstring("{:#12_b}", [0b11110000]), content="0b1111_0000 ")
  
  // All specifiers combined (where applicable)
  inspect(fstring("{:*>12#_x}", [0xABCDEF]), content="**0xabc_def")
}

///|
test "formatter/string_special_cases" {
  // Test string formatting edge cases
  
  // Empty string
  inspect(fstring("{}", [""]), content="")
  inspect(fstring("{:10}", [""]), content="          ")
  inspect(fstring("{:>10}", [""]), content="          ")
  inspect(fstring("{:*^10}", [""]), content="**********")
  
  // Single character strings
  inspect(fstring("{:5}", ["a"]), content="a    ")
  inspect(fstring("{:>5}", ["a"]), content="    a")
  inspect(fstring("{:^5}", ["a"]), content="  a  ")
  
  // Strings with special characters
  inspect(fstring("{:10}", ["\n"]), content="\n         ")
  inspect(fstring("{:10}", ["\t"]), content="\t         ")
  inspect(fstring("{:5}", ["\\\""]), content="\\\"   ")
}

///|
test "formatter/boolean_alignment" {
  // Test boolean formatting with alignment
  inspect(fstring("{:8}", [true]), content="true    ")
  inspect(fstring("{:8}", [false]), content="false   ")
  inspect(fstring("{:>8}", [true]), content="    true")
  inspect(fstring("{:>8}", [false]), content="   false")
  inspect(fstring("{:^8}", [true]), content="  true  ")
  inspect(fstring("{:^8}", [false]), content=" false  ")
  
  // Boolean with custom fill
  inspect(fstring("{:*>8}", [true]), content="****true")
  inspect(fstring("{:->8}", [false]), content="---false")
  inspect(fstring("{:.^8}", [true]), content="..true..")
}

///|
test "formatter/char_formatting" {
  // Test character formatting specifics
  inspect(fstring("{}", ['A']), content="A")
  inspect(fstring("{:3}", ['B']), content="B  ")
  inspect(fstring("{:>3}", ['C']), content="  C")
  inspect(fstring("{:^3}", ['D']), content=" D ")
  
  // Special characters
  inspect(fstring("{}", [' ']), content=" ")
  inspect(fstring("{:>3}", [' ']), content="   ") // Space character
  inspect(fstring("{}", ['\n']), content="\n")
  inspect(fstring("{}", ['\t']), content="\t")
  
  // Unicode characters
  inspect(fstring("{}", ['🌟']), content="🌟")
  inspect(fstring("{:>5}", ['🌟']), content="    🌟")
  inspect(fstring("{:*<5}", ['🌟']), content="🌟****")
}

///|
test "formatter/precision_with_non_floats" {
  // Test that precision is ignored for non-float types
  inspect(fstring("{:.2d}", [123]), content="123") // Should ignore precision
  inspect(fstring("{:.5s}", ["hello"]), content="hello") // Precision might not apply to strings
  inspect(fstring("{:.3c}", ['A']), content="A") // Should ignore precision
  inspect(fstring("{:.2b}", [15]), content="1111") // Should ignore precision
}

///|
test "formatter/mixed_types_in_same_format" {
  // Test mixing different types in the same format string
  inspect(
    fstring("{} {} {} {} {} {}", [42, "hello", true, 3.14, 'A', -1]),
    content="42 hello true 3.14 A -1"
  )
  
  // With different format specifications
  inspect(
    fstring("{:>5} {:<10} {:^8} {:>6.2f} {:*>3} {:x}", 
           [42, "test", true, 3.14159, 'X', 255]),
    content="   42 test       true    3.14 **X ff"
  )
}