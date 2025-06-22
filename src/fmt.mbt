///|
fn format_part(part : FormatPart, values : Array[Json]) -> String {
  let sb = StringBuilder::new()
  match part {
    LocField(loc~, spec~) => {
      let value = values[loc]
      let string = match spec.typ {
        Digit | Binary | Octal | HexLower | HexUpper =>
          format_digit(spec, value)
        Float | ExponentLower | ExponentUpper | Percent =>
          format_float(spec, value)
        Default =>
          match value {
            Json::String(s) => s
            Json::Number(n) => n.to_string()
            Json::True => "true"
            Json::False => "false"
            Json::Null => "None"
            Json::Array(arr) => arr.to_string()
            Json::Object(obj) => obj.to_string()
          }
      }
      align_string(spec, string, sb)
    }
    Text(text~) => sb.write_string(text)
  }
  sb.to_string()
}

///|
fn align_string(spec : FormatSpec, value : String, sb : StringBuilder) -> Unit {
  let width = spec.width.or(0)
  let mut value = value
  let padding = width - value.length()
  let fill = spec.options.fill.or(' ')
  if spec.options.sharp {
    value = match spec.typ {
      SpecType::Binary => "0b" + value
      SpecType::Octal => "0o" + value
      SpecType::HexLower => "0x" + value
      SpecType::HexUpper => "0X" + value
      _ => value
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
fn format_float(spec : FormatSpec, value : Json) -> String {
  if not(value is Json::Number(_)) {
    abort("format_float expects a number")
  }
  let value = value.as_number().unwrap()
  let doble_string = match spec.typ {
    Float =>
      if not(spec.precision is None) {
        @ryu.ryu_to_string_precision(value, precision=spec.precision.unwrap())
      } else {
        value.to_string() // Default is JavaScript specific
      }
    ExponentLower =>
      @ryu.ryu_to_string_exp(value, precision=spec.precision.or(6), upper=false)
    ExponentUpper =>
      @ryu.ryu_to_string_exp(value, precision=spec.precision.or(6), upper=true)
    Percent => {
      let percent_value = value * 100.0
      @ryu.ryu_to_string_precision(
        percent_value,
        precision=spec.precision.or(2),
      ) +
      "%"
    }
    _ => value.to_string()
  }
  doble_string
}

///|
fn format_digit(spec : FormatSpec, value : Json) -> String {
  if not(value is Json::Number(_)) {
    abort("format_digit expects a number")
  }
  let value = value.as_number().unwrap().to_int64()
  let mut num_string = match spec.typ {
    Binary => value.to_string(radix=2)
    Octal => value.to_string(radix=8)
    HexLower => value.to_string(radix=16)
    HexUpper => value.to_string(radix=16).to_upper()
    Digit => value.to_string()
    _ => value.to_string()
  }
  let digit_group = fn(grouping : Char, num_string : String, cnt : Int) {
    let new_num_string = StringBuilder::new()
    for idx, char in num_string {
      if idx > 0 && idx % cnt == 0 {
        new_num_string.write_char(grouping)
      }
      new_num_string.write_char(char)
    }
    new_num_string.to_string()
  }
  if spec.grouping is Default {
    return num_string
  }
  num_string = match (spec.grouping, spec.typ) {
    (Comma, Digit) => digit_group(',', num_string, 3)
    (Underscore, Digit) => digit_group('_', num_string, 3)
    (Underscore, Octal | HexLower | HexUpper | Binary) =>
      // For underscore grouping, we can apply it to binary, octal, and hex
      digit_group('_', num_string, 4)
    (_, _) => abort("Unsupported grouping for this type")
  }
  num_string
}

///|
fn format(parts : Array[FormatPart], values : Array[&Formatter]) -> String {
  let result = StringBuilder::new()
  for part in parts {
    match part {
      LocField(loc~, spec~) => {
        let value = values[loc]
        value.display(spec, result)
      }
      Text(text~) => result.write_string(text)
    }
  }
  result.to_string()
}

///|
/// Formats a string with placeholders using the provided formatter values.
///
/// Parses the format string to identify placeholders and literal text, then
/// applies the formatter values to fill the placeholders according to their
/// specifications. This function provides a flexible way to create formatted
/// strings with type-safe value insertion.
///
/// Parameters:
///
/// * `parts` : The format string containing placeholders (e.g., `{0}`, `{1:x}`)
/// and literal text to be formatted.
/// * `values` : An array of formatter objects that implement the `Formatter`
/// trait, used to fill the placeholders in the format string.
///
/// Returns the formatted string with all placeholders replaced by their
/// corresponding formatted values.
///
/// Example:
///
/// ```moonbit
/// let name = "Alice"
/// let age = 30
/// let formatted = @fmt.fstring("Hello, {0}! You are {1} years old.", [name, age])
/// inspect(formatted, content="Hello, Alice! You are 30 years old.")
/// ```
///
pub fn fstring(parts : String, values : Array[&Formatter]) -> String {
  let parts = parse_format_string(parts)
  format(parts, values)
}

///|
/// Formats a string with placeholders using the provided formatter values and
/// prints it to standard output followed by a newline.
///
/// This function combines string formatting and output in a single operation. It
/// parses the format string, applies the formatter values to fill placeholders,
/// and outputs the result.
///
/// Parameters:
///
/// * `parts` : The format string containing placeholders and literal text to be
/// formatted.
/// * `values` : An array of formatter objects that implement the `Formatter`
/// trait, used to fill the placeholders in the format string.
///
/// Example:
///
/// ```moonbit
/// let name = "Alice"
/// let age = 30
/// @fmt.fprintln("Hello, {0}! You are {1} years old.", [name, age])
/// // Outputs: Hello, Alice! You are 30 years old.
/// ```
///
pub fn fprintln(parts : String, values : Array[&Formatter]) -> Unit {
  fstring(parts, values) |> println
}

///|
fn jformat(parts : Array[FormatPart], values : Array[Json]) -> String {
  let result = StringBuilder::new()
  for part in parts {
    let formatted_value = format_part(part, values)
    result.write_string(formatted_value)
  }
  result.to_string()
}

///|
/// Formats a string with placeholders using the provided JSON values.
///
/// Parses the format string to identify placeholders and literal text, then
/// applies the JSON values to fill the placeholders according to their
/// specifications. This function provides a flexible way to create formatted
/// strings using JSON data as input.
///
/// Parameters:
///
/// * `parts` : The format string containing placeholders (e.g., `{0}`, `{1:x}`)
///  and literal text to be formatted.
/// * `values` : A JSON array containing the values used to fill the placeholders
///  in the format string. Each element corresponds to a placeholder position.
///
/// Returns the formatted string with all placeholders replaced by their
/// corresponding formatted values from the JSON array.
///
/// Panics if `values` is not a JSON array.
///
/// Example:
///
/// ```moonbit
/// let data = @json.parse("[\"Alice\", 30]")
/// let formatted = @fmt.jstring("Hello, {0}! You are {1} years old.", data)
/// inspect(formatted, content="Hello, Alice! You are 30 years old.")
/// ```
///
pub fn jstring(parts : String, values : Json) -> String {
  let parts = parse_format_string(parts)
  match values {
    Json::Array(_) => ()
    _ => abort("fprintln expects an array of values")
  }
  jformat(parts, values.as_array().unwrap())
}

///|
/// Formats a string with placeholders using the provided JSON values and prints
/// it to standard output followed by a newline.
///
/// This function combines string formatting and output in a single operation. It
/// parses the format string, applies the JSON values to fill placeholders
/// according to their specifications, and outputs the result to the console.
///
/// Parameters:
///
/// * `parts` : The format string containing placeholders (e.g., `{0}`, `{1:x}`)
/// and literal text to be formatted.
/// * `values` : A JSON array containing the values used to fill the placeholders
/// in the format string. Each element corresponds to a placeholder position.
///
/// Panics if `values` is not a JSON array.
///
/// Example:
///
/// ```moonbit
/// let data = @json.parse("[\"Alice\", 30]")
/// @fmt.jprintln("Hello, {0}! You are {1} years old.", data)
/// // Outputs: Hello, Alice! You are 30 years old.
/// ```
///
pub fn jprintln(parts : String, values : Json) -> Unit {
  jstring(parts, values) |> println
}
