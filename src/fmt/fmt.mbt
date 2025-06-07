///|
fn format_part(part : FormatPart, values : Array[Json]) -> String {
  let sb = StringBuilder::new()
  match part {
    LocField(loc~, spec~) => {
      let value = values[loc]
      match spec.typ {
        Digit | Binary | Octal | HexLower | HexUpper =>
          format_digit(spec, value, sb)
        Float | ExponentLower | ExponentUpper => format_float(spec, value, sb)
        Default =>
          match value {
            Json::String(s) => align_string(spec, s, sb)
            Json::Number(n) => {
              let num_string = n.to_string()
              align_string(spec, num_string, sb)
            }
            Json::True => align_string(spec, "true", sb)
            Json::False => align_string(spec, "false", sb)
            Json::Null => align_string(spec, "none", sb)
            _ => {
              // For unsupported types, just convert to string
              let value_string = value.to_string()
              align_string(spec, value_string, sb)
            }
          }
        String =>
          match value {
            Json::String(s) => align_string(spec, s, sb)
            _ => abort("String format specifier expects a string value")
          }
        Char =>
          match value {
            Json::String(s) if s.length() == 1 => align_string(spec, s, sb)
            _ =>
              abort("Char format specifier expects a single character string")
          }
      }
    }
    Text(text~) => sb.write_string(text)
  }
  sb.to_string()
}

///|
fn align_string(spec : FormatSpec, value : String, sb : StringBuilder) -> Unit {
  let width = spec.width.or(0)
  let padding = width - value.length()
  if padding > 0 {
    match spec.options.align {
      Align::Left => sb.write_string(value.pad_end(padding, ' '))
      Align::Right => sb.write_string(value.pad_start(padding, ' '))
      Align::Center => {
        let left_padding = padding / 2
        let right_padding = padding - left_padding
        sb.write_string(
          value.pad_start(left_padding, ' ').pad_end(right_padding, ' '),
        )
      }
    }
  } else {
    sb.write_string(value)
  }
}

///|
fn trim_or_pad_decimal(value : String, precision : Int) -> String {
  let sb = StringBuilder::new()
  if precision < 0 {
    return value
  }
  let parts = value.split(".").map(@string.View::to_string).collect()
  sb.write_string(parts[0])
  sb.write_char('.')
  if parts.length() == 1 {
    sb.write_string("0".pad_end(precision, '0'))
    return sb.to_string()
  }
  let decimal_part = parts[1]
  if decimal_part.length() > precision {
    sb.write_string(decimal_part.charcodes(end=precision).to_string())
  } else {
    sb.write_string(decimal_part.pad_end(precision, '0'))
  }
  sb.to_string()
}

///|
fn format_float(spec : FormatSpec, value : Json, sb : StringBuilder) -> Unit {
  match value {
    Json::Number(num) => {
      // TODO: need change core to support float formatting
      let num_string = match spec.typ {
        Float => trim_or_pad_decimal(ryu_to_string(num, false), spec.precision)
        ExponentLower => ryu_to_string(num, true)
        ExponentUpper => ryu_to_string(num, true).to_upper()
        _ => abort("Unsupported format type for float")
      }

      // Align the string according to the spec
      align_string(spec, num_string, sb)
    }
    _ => abort("format_float expects a number")
  }
}

///|
fn format_digit(spec : FormatSpec, value : Json, sb : StringBuilder) -> Unit {
  match value {
    Json::Number(num) => {
      let num = num.to_int64()
      let num_string = match spec.typ {
        SpecType::Binary => num.to_string(radix=2)
        SpecType::Octal => num.to_string(radix=8)
        SpecType::HexLower => num.to_string(radix=16)
        SpecType::HexUpper => num.to_string(radix=16).to_upper()
        _ => abort("Unsupported format type for digit")
      }

      // TODO: Handle grouping 
      match spec.grouping {
        _ => ...
      }

      // Align the string according to the spec
      align_string(spec, num_string, sb)
    }
    _ => abort("format_digit expects a number")
  }
}

///|
pub fn format(parts : Array[FormatPart], values : Array[Json]) -> String {
  let result = StringBuilder::new()
  for idx in 0..<parts.length() {
    let part = parts[idx]
    let formatted_value = format_part(part, values)
    result.write_string(formatted_value)
  }
  result.to_string()
}

///|
pub fn fprintln(parts : String, values : Json) -> Unit {
  let parts = parse_format_string(parts)
  match values {
    Json::Array(_) => ()
    _ => abort("fprintln expects an array of values")
  }
  match parts {
    Ok(parts) => {
      let formatted = format(parts, values.as_array().unwrap())
      println(formatted)
    }
    Err(e) => abort("Failed to parse format string: " + e.to_string())
  }
}

///|
pub fn fstring(parts : String, values : Json) -> String {
  let parts = parse_format_string(parts)
  match values {
    Json::Array(_) => ()
    _ => abort("fprintln expects an array of values")
  }
  match parts {
    Ok(parts) => format(parts, values.as_array().unwrap())
    Err(e) => abort("Failed to parse format string: " + e.to_string())
  }
}
