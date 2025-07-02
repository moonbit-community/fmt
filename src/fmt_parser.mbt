///|
typealias @string.View as str

///|
pub enum Align {
  Left
  Right
  Center
} derive(Show, Eq)

///|
pub enum Grouping {
  Comma
  Underscore
  Default
} derive(Show)

///|
impl Default for Grouping with default() {
  return Grouping::Default
}

///|
pub enum SpecType {
  Binary
  Digit
  ExponentLower
  ExponentUpper
  Float
  Octal
  HexLower
  HexUpper
  Percent
  Default
} derive(Show)

///|
pub struct Options {
  fill : Char?
  align : Align
  mut sharp : Bool
  mut zero : Bool
} derive(Show)

///|
impl Default for Options with default() {
  return { fill: None, align: Align::Left, sharp: false, zero: false }
}

///|
pub struct FormatSpec {
  options : Options
  width : Int?
  grouping : Grouping
  precision : Int?
  typ : SpecType
} derive(Show)

///|
impl Default for FormatSpec with default() {
  return {
    options: Options::default(),
    width: None,
    grouping: Grouping::Default,
    precision: None,
    typ: SpecType::Default,
  }
}

///|
priv enum FormatPart {
  LocField(loc~ : Int, spec~ : FormatSpec)
  Text(text~ : String)
} derive(Show)

///|
fn match_align_char(c : Char) -> Align {
  match c {
    '<' => Align::Left
    '>' => Align::Right
    '^' => Align::Center
    _ => Align::Left
  }
}

///|
fn is_align_char(c : Char) -> Bool {
  return ['<', '>', '^'].contains(c)
}

///|
fn parse_fill_align(input : str) -> (Char?, Align, str) {
  match input {
    [any, align_c, .. input] if is_align_char(align_c) =>
      (Some(any), match_align_char(align_c), input)
    [align_c, .. chars] if is_align_char(align_c) =>
      (None, match_align_char(align_c), chars)
    [..] => (None, Left, input)
  }
}

///|
fn parse_options(input : str) -> (Options, str) {
  let (fill, align, input) = parse_fill_align(input)
  let options = { fill, align, sharp: false, zero: false }
  loop input {
    ['#', .. input] => {
      options.sharp = true
      continue input
    }
    ['0', .. input] => {
      options.zero = true
      continue input
    }
    [..] as input => return (options, input)
  }
  return (options, input)
}

///|
fn parse_digit(input : str) -> (Int?, str) {
  let mut result = 0
  let mut idx = 0
  for c in input {
    if not(c.is_digit(10)) {
      break
    }
    result = result * 10 + (Char::to_int(c) - '0')
    idx += 1
  }
  if idx == 0 {
    (None, input)
  } else {
    (Some(result), input.charcodes(start=idx))
  }
}

///|
fn parse_grouping(input : str) -> (Grouping?, str) {
  match input {
    [',', .. chars] => return (Some(Grouping::Comma), chars)
    ['_', .. chars] => return (Some(Grouping::Underscore), chars)
    [..] => return (None, input)
  }
}

///|
fn parse_precision(input : str) -> (Int?, str) {
  match input {
    ['.', .. input] => {
      let (prec, rest) = parse_digit(input)
      (prec, rest)
    }
    _ => (None, input)
  }
}

///|
fn parse_type(input : str) -> (SpecType, str) {
  match input {
    ['b', .. input] => (Binary, input)
    ['d', .. input] => (Digit, input)
    ['e', .. input] => (ExponentLower, input)
    ['E', .. input] => (ExponentUpper, input)
    ['f', .. input] => (Float, input)
    ['o', .. input] => (Octal, input)
    ['x', .. input] => (HexLower, input)
    ['X', .. input] => (HexUpper, input)
    ['%', .. input] => (Percent, input)
    _ => (Default, input)
  }
}

///|
fn parse_spec(input : str) -> (FormatSpec, str) {
  // 1. options
  let (options, rest1) = parse_options(input)
  // 2. width
  let (width, rest2) = parse_digit(rest1)
  // 3. grouping
  let (grouping, rest3) = parse_grouping(rest2)
  // 4. precision
  let (precision, rest4) = parse_precision(rest3)
  // 5. type
  let (typ, rest5) = parse_type(rest4)
  let spec = { options, width, grouping: grouping.or_default(), precision, typ }
  (spec, rest5)
}

///|
fn parse_format_part(input : str, last~ : Int) -> (FormatPart, str) {
  let (loc, input) = parse_digit(input)
  let loc = loc.or(last)
  let default = LocField(loc~, spec=FormatSpec::default())
  match input {
    [':', .. input] => {
      let (spec, input) = parse_spec(input)
      (LocField(loc~, spec~), input)
    }
    [..] => (default, input)
  }
}

///|
fn parse_text(input : str) -> (String, str) {
  let mut idx = 0
  let buf = StringBuilder::new()
  for char in input {
    if char == '{' || char == '}' {
      break
    }
    buf.write_char(char)
    idx += 1
  }
  (buf.to_string(), input.charcodes(start=idx))
}

///|
fn parse_braces(input : str) -> (Char?, str) {
  if input.has_prefix("{{") {
    (Some('{'), input.charcodes(start=2))
  } else if input.has_prefix("}}") {
    (Some('}'), input.charcodes(start=2))
  } else {
    (None, input)
  }
}

///|
fn parse_format_string(input : String) -> Array[FormatPart] {
  let parts = Array::new()
  let mut last = 0
  let mut chars = input[:]
  let buf = StringBuilder::new()
  while not(chars.is_empty()) {
    let (text, new_chars) = parse_text(chars)
    buf.write_string(text)
    let (c, new_chars) = parse_braces(new_chars)
    chars = new_chars
    if c is Some(v) {
      buf.write_char(v)
    }
    if not(buf.is_empty()) {
      parts.push(Text(text=buf.to_string()))
      buf.reset()
    }
    match new_chars {
      ['{', .. new_chars] => {
        let (spec, new_chars) = parse_format_part(new_chars, last~)
        chars = new_chars.charcodes(start=1) // Skip the '}'
        last += 1
        parts.push(spec)
      }
      ['}', .. new_chars] =>
        if new_chars.has_prefix("}") {
          // This is a literal '}' in the format string
          buf.write_char('}')
          parts.push(Text(text=buf.to_string()))
          chars = new_chars.charcodes(start=1) // Skip the '}'
        } else {
          // If we reach here, it means we have an unmatched '}'
          abort("Unmatched '}' in format string")
        }
      [..] => continue
    }
  }
  parts
}

///|
test "parse_spec_precision" {
  let input = ".2f"
  let (spec, _) = match parse_spec(input[:]) {
    result => result
  }
  inspect(
    spec,
    content="{options: {fill: None, align: Left, sharp: false, zero: false}, width: None, grouping: Default, precision: Some(2), typ: Float}",
  )
}

///|
test "parse_spec_width" {
  let input = "10d"
  let (spec, _) = match parse_spec(input[:]) {
    result => result
  }
  inspect(
    spec,
    content="{options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}",
  )
}

///|
test "parse_format_part" {
  let input = "3:10d"
  let (part, rest) = match parse_format_part(input[:], last=0) {
    result => result
  }
  inspect(
    part,
    content="LocField(loc=3, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit})",
  )
  inspect(rest, content="")
}

///|
test "parse_fmt_string" {
  let input = "{:10d} {0:10d} {1:10d} {{}}"
  let result = match parse_format_string(input) {
    parts => parts
  }
  inspect(
    result,
    content=(
      #|[LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" "), LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" "), LocField(loc=1, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" {"), Text(text="}")]
    ),
  )
}

///|
test "parse_pure_braces" {
  let input = "{{}}"
  let result = match parse_format_string(input) {
    parts => parts
  }
  inspect(
    result,
    content=(
      #|[Text(text="{"), Text(text="}")]
    ),
  )
}


test "parse_example_13" {
  let input = "{:<#8x}"
  let result = match parse_format_string(input) {
    parts => parts
  }
  inspect(
    result,
    content=(
      "[LocField(loc=0, spec={options: {fill: None, align: Left, sharp: true, zero: false}, width: Some(8), grouping: Default, precision: None, typ: HexLower})]"
    ),
  )
}