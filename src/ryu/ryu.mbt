// Double to FixedString

///|
let gPOW10_ADDITIONAL_BITS = 120

///|
let gADDITIONAL_BITS_2 = 120

///|
fn pow10BitsForIndex(idx : Int) -> Int {
  return 16 * idx + gPOW10_ADDITIONAL_BITS
}

///|
fn indexForExponent(e : Int) -> Int {
  return (e + 15) / 16
}

///|
fn lengthForIndex(idx : Int) -> Int {
  // +1 for ceil, +16 for mantissa, +8 to round up when dividing by 9
  return (log10Pow2(16 * idx) + 1 + 16 + 8) / 9
}

///|
fn umlh(a : UInt64, b : UInt64) -> UInt64 {
  // Returns the low and high parts of the 128-bit product.
  // The low part is lo, and the high part is hi.

  let (_, hi) = umul128(a, b)
  hi
}

///|
fn div1e9(x : UInt64) -> UInt64 {
  umlh(x >> 9, 0x44B82FA09B5A53UL) >> 11
}

///|
fn mod1e9(x : UInt64) -> Int {
  (x - 1000000000 * div1e9(x)).to_int()
}

///|
fn mulShift_mod1e9(m : UInt64, mul : Array[UInt64], j : Int) -> Int {
  let (_, high0) = umul128(m, mul[0])
  let (low1, high1) = umul128(m, mul[1])
  let (low2, high2) = umul128(m, mul[2])
  let s0high = low1 + high0
  let c1 = s0high < low1
  let s1low = low2 + high1 + c1.to_uint64()
  let c2 = s1low < low2
  let s1high = high2 + c2.to_uint64()
  if j < 160 {
    let r0 = mod1e9(s1high).to_uint64()
    let r1 = mod1e9((r0 << 32) | (s1low >> 32)).to_uint64()
    let r2 = (r1 << 32) | (s1low & 0xFFFFFFFFUL)
    return mod1e9(r2 >> (j - 128))
  } else {
    let r0 = mod1e9(s1high).to_uint64()
    let r1 = mod1e9((r0 << 32) | (s1low >> 32)).to_uint64()
    return mod1e9(r1 >> (j - 160))
  }
}

// Returns the number of decimal digits in v, which must not contain more than 9 digits.
///|
fn decimalLength9(v : Int) -> Int {
  // Function precondition: v is not a 10-digit number.
  // (f2s: 9 digits are sufficient for round-tripping.)
  // (d2fixed: We print 9-digit blocks.)
  if v >= 100000000 {
    return 9
  }
  if v >= 10000000 {
    return 8
  }
  if v >= 1000000 {
    return 7
  }
  if v >= 100000 {
    return 6
  }
  if v >= 10000 {
    return 5
  }
  if v >= 1000 {
    return 4
  }
  if v >= 100 {
    return 3
  }
  if v >= 10 {
    return 2
  }
  return 1
}

///|
test "db2string" {
  inspect(
    ryu_to_string_precision(12345.123456, precision=3),
    content="12345.123",
  )
}

///|
test "db2string2" {
  inspect(ryu_to_string_precision(12345.123456, precision=0), content="12345")
}

///|
test "db2string3" {
  inspect(
    ryu_to_string_precision(12345.123456, precision=10),
    content="12345.1234560000",
  )
}

///|
test "db2string4" {
  inspect(
    ryu_to_string_precision(12345.123456, precision=17),
    content="12345.12345599999935075",
  )
}

// TODO: roundUp 
///|
test "db2string5" {
  inspect(
    ryu_to_string_precision(-8888888.1, precision=1),
    content="-8888888.1",
  )
}

///|
fn write_digits(
  array : FixedArray[Byte],
  start : Int,
  len : Int,
  digits : Int
) -> Unit {
  let mut idx = start + len - 1
  let mut digits = digits
  for i in 0..<len {
    array[idx] = (48 + digits % 10).to_byte()
    digits /= 10
    idx -= 1
  }
}

///|
test "write_digits" {
  let array = FixedArray::make(10, Byte::default())
  write_digits(array, 0, 3, 123)
  inspect(string_from_bytes(array, 0, 3), content="123")
}

///|
fn write_nine_digits(
  array : FixedArray[Byte],
  start : Int,
  digits : Int
) -> Unit {
  write_digits(array, start, 9, digits)
}

///|
fn write_chars(
  array : FixedArray[Byte],
  start : Int,
  len : Int,
  char : Byte
) -> Unit {
  let mut idx = start
  for _ in 0..<len {
    array[idx] = char
    idx += 1
  }
}

///|
fn write_decimal_digits(
  array : FixedArray[Byte],
  start : Int,
  len : Int,
  digits : Int
) -> Unit {
  let mut idx = start + len
  let mut digits = digits
  for i in 0..<(len - 1) {
    array[idx] = (48 + digits % 10).to_byte()
    digits /= 10
    idx -= 1
  }
  array[idx] = b'.'
  idx -= 1
  array[idx] = (48 + digits).to_byte()
  idx -= 1
}

///|
test "write_decimal_digits" {
  let array = FixedArray::make(10, Byte::default())
  write_decimal_digits(array, 0, 5, 12345)
  inspect(string_from_bytes(array, 0, 6), content="1.2345")
}

///|
fn write_string(array : FixedArray[Byte], start : Int, str : Bytes) -> Unit {
  let mut idx = start
  for byte in str {
    array[idx] = byte
    idx += 1
  }
}

///|
pub fn ryu_to_string_precision(val : Double, precision~ : Int = 17) -> String {
  let result = FixedArray::make(25, Byte::default())
  let bits : UInt64 = val.reinterpret_as_uint64()
  let ieeeSign = (
      (bits >> (gDOUBLE_MANTISSA_BITS + gDOUBLE_EXPONENT_BITS)) & 1UL
    ) !=
    0UL
  let ieeeMantissa : UInt64 = bits & ((1UL << gDOUBLE_MANTISSA_BITS) - 1UL)
  let ieeeExponent : Int = ((bits >> gDOUBLE_MANTISSA_BITS) &
  ((1UL << gDOUBLE_EXPONENT_BITS) - 1UL)).to_int()
  if ieeeExponent == (1 << gDOUBLE_EXPONENT_BITS) - 1 ||
    (ieeeExponent == 0 && ieeeMantissa == 0UL) {
    return copy_special_str(ieeeSign, ieeeExponent != 0, ieeeMantissa != 0UL)
  }
  if ieeeExponent == 0 && ieeeMantissa == 0 {
    let mut index = 0
    if ieeeSign {
      result[index] = b'-'
      index += 1
    }
    result[index] = b'0'
    index += 1
    if precision > 0 {
      result[index] = b'.'
      index += 1
      write_chars(result, index, precision, b'0')
      index += precision
    }
    return string_from_bytes(result, 0, index)
  }
  let (e2, m2) = if ieeeExponent == 0 {
    (1 - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS, ieeeMantissa)
  } else {
    (
      ieeeExponent - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS,
      (1UL << gDOUBLE_MANTISSA_BITS) | ieeeMantissa,
    )
  }
  let mut index = 0
  let mut nonzero = false
  if ieeeSign {
    result[index] = b'-'
    index += 1
  }
  if e2 >= -52 {
    let idx2 = if e2 < 0 { 0 } else { indexForExponent(e2) }
    let p10bits = pow10BitsForIndex(idx2)
    let len = lengthForIndex(idx2)
    for i = len - 1; i >= 0; i = i - 1 {
      let j = p10bits - e2
      let digits = mulShift_mod1e9(
        m2 << 8,
        gPOW10_SPLIT[gPOW10_OFFSET[idx2] + i],
        j + 8,
      )
      if nonzero {
        write_nine_digits(result, index, digits)
        index += 9
      } else if digits != 0 {
        let olength = decimalLength9(digits)
        write_digits(result, index, olength, digits)
        index += olength
        nonzero = true
      }
    }
  }
  if not(nonzero) {
    result[index] = b'0'
    index += 1
  }
  if precision > 0 {
    result[index] = b'.'
    index += 1
  }
  if e2 < 0 {
    let idx2 = -e2 / 16
    let blocks = precision / 9 + 1
    let mut roundUp = 0
    let mut i = 0
    if blocks <= gMIN_BLOCK_2[idx2] {
      i = blocks
      write_chars(result, index, precision, b'0')
      index += precision
    } else if i < gMIN_BLOCK_2[idx2] {
      i = gMIN_BLOCK_2[idx2]
      write_chars(result, index, 9 * i, b'0')
      index += i * 9
    }
    for i = i; i < blocks; i = i + 1 {
      let j = gADDITIONAL_BITS_2 + (-e2 - 16 * idx2)
      let p = gPOW10_OFFSET_2[idx2] + i - gMIN_BLOCK_2[idx2]
      if p >= gPOW10_OFFSET_2[idx2 + 1] {
        let fill = precision - 9 * i
        write_chars(result, index, fill, b'0')
        index += fill
        break
      }
      let mut digits = mulShift_mod1e9(m2 << 8, gPOW10_SPLIT_2[p], j + 8)
      // println("digits: " + digits.to_string())
      if i < blocks - 1 {
        write_nine_digits(result, index, digits)
        index += 9
      } else {
        let maximum = precision - 9 * i
        let mut lastDigit = 0
        for k in 0..<(9 - maximum) {
          lastDigit = digits % 10
          digits /= 10
        }
        if lastDigit != 5 {
          roundUp = (lastDigit > 5).to_int()
        } else {
          let requiredTwos = -e2 - precision - 1
          let trailingZeros = requiredTwos <= 0 ||
            (requiredTwos < 60 && multipleOfPowerOf2(m2, requiredTwos))
          roundUp = if trailingZeros { 2 } else { 1 }
        }
        if maximum > 0 {
          write_digits(result, index, maximum, digits)
          index += maximum
        }
        break
      }
    }

    // TODO: Implement rounding logic
    if roundUp != 0 {
      let mut roundIndex = index
      let mut dotIndex = 0
      while true {
        roundIndex -= 1
        if roundIndex == -1 || result[roundIndex] == '-' {
          result[roundIndex + 1] = b'1'
          if dotIndex > 0 {
            result[dotIndex] = b'0'
            result[dotIndex + 1] = b'.'
          }
          result[index] = b'0'
          index += 1
          break
        }
        if result[roundIndex] == b'.' {
          dotIndex = roundIndex
          continue
        } else if result[roundIndex] == b'9' {
          result[roundIndex] = b'0'
          roundUp = 1
          continue
        } else {
          if roundUp == 2 && result[roundIndex] % 2 == 0 {
            break
          }
          result[roundIndex] = result[roundIndex] + 1
          break
        }
      }
    }
  } else {
    write_chars(result, index, precision, b'0')
    index += precision
  }
  // println(result.to_string())
  // println("idx: " + idx.to_string())
  return string_from_bytes(result, 0, index)
}

///|
pub fn ryu_to_string_exp(
  val : Double,
  precision~ : Int = 17,
  upper~ : Bool = false
) -> String {
  let mut precision = precision
  let result = FixedArray::make(25, Byte::default())
  let bits : UInt64 = val.reinterpret_as_uint64()
  let ieeeSign = (
      (bits >> (gDOUBLE_MANTISSA_BITS + gDOUBLE_EXPONENT_BITS)) & 1UL
    ) !=
    0UL
  let ieeeMantissa : UInt64 = bits & ((1UL << gDOUBLE_MANTISSA_BITS) - 1UL)
  let ieeeExponent : Int = ((bits >> gDOUBLE_MANTISSA_BITS) &
  ((1UL << gDOUBLE_EXPONENT_BITS) - 1UL)).to_int()
  if ieeeExponent == (1 << gDOUBLE_EXPONENT_BITS) - 1 ||
    (ieeeExponent == 0 && ieeeMantissa == 0UL) {
    return copy_special_str(ieeeSign, ieeeExponent != 0, ieeeMantissa != 0UL)
  }
  if ieeeExponent == 0 && ieeeMantissa == 0 {
    let mut index = 0
    if ieeeSign {
      result[index] = b'-'
      index += 1
    }
    result[index] = b'0'
    index += 1
    if precision > 0 {
      result[index] = b'.'
      index += 1
      write_chars(result, index, precision, b'0')
      index += precision
    }
    write_string(result, index, if upper { b"E+00" } else { b"e+00" })
    index += 4
    return string_from_bytes(result, 0, index)
  }
  let (e2, m2) = if ieeeExponent == 0 {
    (1 - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS, ieeeMantissa)
  } else {
    (
      ieeeExponent - gDOUBLE_BIAS - gDOUBLE_MANTISSA_BITS,
      (1UL << gDOUBLE_MANTISSA_BITS) | ieeeMantissa,
    )
  }
  let printDecimalPoint = precision > 0
  precision += 1
  let mut index = 0
  if ieeeSign {
    result[index] = b'-'
    index += 1
  }
  let mut digits = 0
  let mut printedDigits = 0
  let mut avaiableDigits = 0
  let mut exp = 0
  if e2 >= -52 {
    let idx = if e2 < 0 { 0 } else { indexForExponent(e2) }
    let p10bits = pow10BitsForIndex(idx)
    let len = lengthForIndex(idx)
    for i = len - 1; i >= 0; i = i - 1 {
      let j = p10bits - e2
      digits = mulShift_mod1e9(
        m2 << 8,
        gPOW10_SPLIT[gPOW10_OFFSET[idx] + i],
        j + 8,
      )
      if printedDigits != 0 {
        if printedDigits + 9 > precision {
          avaiableDigits = 9
          break
        }
        write_nine_digits(result, index, digits)
        index += 9
        printedDigits += 9
      } else if digits != 0 {
        avaiableDigits = decimalLength9(digits)
        exp = i * 9 + avaiableDigits - 1
        if avaiableDigits > precision {
          break
        }
        if printDecimalPoint {
          write_decimal_digits(result, index, avaiableDigits, digits)
          index += avaiableDigits + 1
        } else {
          result[index] = b'0' + digits.to_byte()
          index += 1
        }
        printedDigits = avaiableDigits
        avaiableDigits = 0
      }
    }
  }
  if e2 < 0 && avaiableDigits == 0 {
    let idx = -e2 / 16
    for i = gMIN_BLOCK_2[idx]; i < 200; i = i + 1 {
      let j = gADDITIONAL_BITS_2 + (-e2 - 16 * idx)
      let p = gPOW10_OFFSET_2[idx] + i - gMIN_BLOCK_2[idx]
      digits = if p >= gPOW10_OFFSET_2[idx + 1] {
        0
      } else {
        mulShift_mod1e9(m2 << 8, gPOW10_SPLIT_2[p], j + 8)
      }
      if printedDigits != 0 {
        if printedDigits + 9 > precision {
          avaiableDigits = 9
          break
        }
        write_nine_digits(result, index, digits)
        index += 9
        printedDigits += 9
      } else if digits != 0 {
        avaiableDigits = decimalLength9(digits)
        exp = -(i + 1) * 9 + avaiableDigits - 1
        if avaiableDigits > precision {
          break
        }
        if printDecimalPoint {
          write_decimal_digits(result, index, avaiableDigits, digits)
          index += avaiableDigits + 1
        } else {
          result[index] = b'0' + digits.to_byte()
          index += 1
        }
        printedDigits = avaiableDigits
        avaiableDigits = 0
      }
    }
  }
  let maximum = precision - printedDigits
  if avaiableDigits == 0 {
    digits = 0
  }
  let mut lastDigit = 0
  if avaiableDigits > maximum {
    for k in 0..<(avaiableDigits - maximum) {
      lastDigit = digits % 10
      digits /= 10
    }
  }
  let mut roundUp = 0
  if lastDigit != 5 {
    roundUp = (lastDigit > 5).to_int()
  } else {
    let rexp = precision - exp
    let requiredTwos = -e2 - rexp
    let mut trailingZeros = requiredTwos <= 0 ||
      (requiredTwos < 60 && multipleOfPowerOf2(m2, requiredTwos))
    if rexp < 0 {
      let requiredFives = -rexp
      trailingZeros = trailingZeros && multipleOfPowerOf5(m2, requiredFives)
    }
    roundUp = if trailingZeros { 2 } else { 1 }
  }
  if printedDigits != 0 {
    if digits == 0 {
      write_chars(result, index, maximum, b'0')
    } else {
      write_digits(result, index, maximum, digits)
    }
    index += maximum
  } else if printDecimalPoint {
    write_decimal_digits(result, index, maximum, digits)
    index += maximum + 1
  } else {
    result[index] = b'0' + digits.to_byte()
    index += 1
  }
  if roundUp != 0 {
    let mut roundIndex = index
    while true {
      roundIndex -= 1
      if roundIndex == -1 || result[roundIndex] == b'-' {
        result[roundIndex + 1] = b'1'
        exp += 1
        break
      }
      if result[roundIndex] == b'.' {
        continue
      } else if result[roundIndex] == b'9' {
        result[roundIndex] = b'0'
        roundUp = 1
        continue
      } else {
        if roundUp == 2 && result[roundIndex] % 2 == 0 {
          break
        }
        result[roundIndex] = result[roundIndex] + 1
        break
      }
    }
  }
  result[index] = if upper { b'E' } else { b'e' }
  index += 1
  if exp < 0 {
    result[index] = b'-'
    index += 1
    exp = -exp
  } else {
    result[index] = b'+'
    index += 1
  }
  if exp >= 100 {
    write_digits(result, index, 3, exp)
    index += 3
  } else {
    write_digits(result, index, 2, exp)
    index += 2
  }

  // println(result.to_string())
  // println("idx: " + idx.to_string())
  return string_from_bytes(result, 0, index)
}

///|
test "ryu_to_string_exp" {
  inspect(
    ryu_to_string_exp(12345.123, precision=3),
    content="1.23451229999999996e+04",
  )
}
