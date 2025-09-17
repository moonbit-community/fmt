///|
fn format_float(spec : FormatSpec, value : Double) -> String {
  let doble_string = match spec.typ {
    Float =>
      if not(spec.precision is None) {
        @ryu.ryu_to_string_precision(value, precision=spec.precision.unwrap())
      } else {
        value.to_string() // Default is JavaScript specific
      }
    ExponentLower =>
      @ryu.ryu_to_string_exp(
        value,
        precision=spec.precision.unwrap_or(6),
        upper=false,
      )
    ExponentUpper =>
      @ryu.ryu_to_string_exp(
        value,
        precision=spec.precision.unwrap_or(6),
        upper=true,
      )
    Percent => {
      let percent_value = value * 100.0
      @ryu.ryu_to_string_precision(
        percent_value,
        precision=spec.precision.unwrap_or(2),
      ) +
      "%"
    }
    _ => value.to_string()
  }
  doble_string
}

///|
fn format_digit(spec : FormatSpec, value : Int64) -> String {
  let mut num_string = match spec.typ {
    Binary => value.to_string(radix=2)
    Octal => value.to_string(radix=8)
    HexLower => value.to_string(radix=16)
    HexUpper => value.to_string(radix=16).to_upper()
    Digit => value.to_string()
    Default => value.to_string()
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
