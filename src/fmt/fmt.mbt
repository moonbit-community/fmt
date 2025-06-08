///|
fn format_part(part : FormatPart, values : Array[Json]) -> String {
  let sb = StringBuilder::new()
  match part {
    LocField(loc~, spec~) => {
      let value = values[loc]
      match spec.typ {
        Digit | Binary | Octal | HexLower | HexUpper =>
          format_digit(spec, value, sb)
        Float | ExponentLower | ExponentUpper | Percent =>
          format_float(spec, value, sb)
        Default =>
          match value {
            Json::String(s) => align_string(spec, s, sb)
            Json::Number(n) => {
              let num_string = n.to_string()
              align_string(spec, num_string, sb)
            }
            Json::True => align_string(spec, "true", sb)
            Json::False => align_string(spec, "false", sb)
            Json::Null => align_string(spec, "None", sb)
            Json::Array(arr) => align_string(spec, arr.to_string(), sb)
            Json::Object(obj) => align_string(spec, obj.to_string(), sb)
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
  let fill = spec.options.fill.or(' ')
  if spec.options.sharp {
    match spec.typ {
      SpecType::Binary => sb.write_string("0b")
      SpecType::Octal => sb.write_string("0o")
      SpecType::HexLower => sb.write_string("0x")
      SpecType::HexUpper => sb.write_string("0X")
      _ => ()
    }
  }
  if spec.options.zero {
    sb.write_string(value.pad_start(width, '0'))
    return
  }
  if padding > 0 {
    match spec.options.align {
      Align::Left => sb.write_string(value.pad_end(padding, fill))
      Align::Right => sb.write_string(value.pad_start(padding, fill))
      Align::Center => {
        let left_padding = padding / 2 + value.length() / 2
        sb.write_string(
          value.pad_start(left_padding, fill).pad_end(padding, fill),
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
      let num_string = match spec.typ {
        Float => trim_or_pad_decimal(ryu_to_string(num, false), spec.precision)
        ExponentLower => ryu_to_string(num, true)
        ExponentUpper => ryu_to_string(num, true, upper=true)
        Percent => {
          let percent_value = num * 100.0
          trim_or_pad_decimal(
            ryu_to_string(percent_value, false),
            spec.precision,
          ) +
          "%"
        }
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
      let mut num_string = match spec.typ {
        Binary => num.to_string(radix=2)
        Octal => num.to_string(radix=8)
        HexLower => num.to_string(radix=16)
        HexUpper => num.to_string(radix=16).to_upper()
        Digit => num.to_string()
        _ => abort("Unsupported format type for digit")
      }
      if not(spec.grouping is Default) {

        // Check if grouping is valid for the type
        if spec.grouping is Comma && not(spec.typ is Digit) {
          abort("Comma grouping is only supported for digit type")
        }
        let cnt = if spec.typ is Digit { 3 } else { 4 }
        let new_num_string = StringBuilder::new()
        for idx, char in num_string {
          if idx > 0 && idx % cnt == 0 {
            match spec.grouping {
              Comma => new_num_string.write_char(',')
              Underscore => new_num_string.write_char('_')
              _ => ()
            }
          }
          new_num_string.write_char(char)
        }
        num_string = new_num_string.to_string()
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
  for part in parts {
    let formatted_value = format_part(part, values)
    result.write_string(formatted_value)
  }
  result.to_string()
}

///|
pub fn fprintln(parts : String, values : Json) -> Unit {
  let parts = try? parse_format_string(parts)
  // println("fprintln called with parts: " + parts.to_string())
  match values {
    Json::Array(_) => ()
    _ => abort("fprintln expects an array of values")
  }
  let values = values.as_array().unwrap()
  match parts {
    Ok(parts) => {
      let formatted = format(parts, values)
      println(formatted)
    }
    Err(e) => abort("Failed to parse format string: " + e.to_string())
  }
}

///|
pub fn fstring(parts : String, values : Json) -> String {
  let parts = try? parse_format_string(parts)
  // println("fstring called with parts: " + parts.to_string())
  match values {
    Json::Array(_) => ()
    _ => abort("fprintln expects an array of values")
  }
  match parts {
    Ok(parts) => format(parts, values.as_array().unwrap())
    Err(e) => abort("Failed to parse format string: " + e.to_string())
  }
}
