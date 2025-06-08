///|
pub type! ParseError String derive(Eq, Show)

///|
typealias @string.View as str

///|
priv enum Align {
  Left
  Right
  Center
} derive(Show, Eq)

///|
priv enum Grouping {
  Comma
  Underscore
  Default
} derive(Show)

///|
impl Default for Grouping with default() {
  return Grouping::Default
}

///|
priv enum SpecType {
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
impl Default for SpecType with default() {
  return SpecType::Default
}

///|
priv struct Options {
  fill : Char?
  align : Align
  sharp : Bool
  zero : Bool
} derive(Show)

///|
fn Options::is_empty(self : Options) -> Bool {
  return self.fill.is_empty() &&
    self.align == Align::Left &&
    not(self.sharp) &&
    not(self.zero)
}

///|
impl Default for Options with default() {
  return { fill: None, align: Align::Left, sharp: false, zero: false }
}

///|
priv struct FormatSpec {
  options : Options
  width : Int?
  grouping : Grouping
  precision : Int
  typ : SpecType
} derive(Show)

///|
impl Default for FormatSpec with default() {
  return {
    options: Options::default(),
    width: None,
    grouping: Grouping::Default,
    precision: 6,
    typ: SpecType::Default,
  }
}

///|
enum FormatPart {
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
  match input {
    ['#', .. chars] => ({ fill, align, sharp: true, zero: true }, chars)
    ['0', .. chars] => ({ fill, align, sharp: false, zero: true }, chars)
    [..] => ({ fill, align, sharp: false, zero: false }, input)
  }
}

///|
fn parse_digit(input : str) -> (Int?, str)!ParseError {
  let mut idx = 0
  while input.length() > idx && input.char_at(idx).is_digit(10) {
    idx += 1
  }
  if idx == 0 {
    (None, input)
  } else {
    let width_str = input.charcodes(start=0, end=idx).to_string()
    let result = try? @strconv.parse_int(width_str, base=10)
    match result {
      Ok(width) => (Some(width), input.charcodes(start=idx))
      Err(_) => raise ParseError("Invalid digit in format specifier")
    }
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
fn parse_precision(input : str) -> (Int?, str)!ParseError {
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
fn parse_spec(input : str) -> (FormatSpec, str)!ParseError {
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
  let spec = {
    options,
    width,
    grouping: grouping.or_default(),
    precision: precision.or(6),
    typ,
  }
  (spec, rest5)
}

///|
fn parse_format_part(input : str, last~ : Int) -> (FormatPart, str)!ParseError {
  let input = input.trim(" ")
  if input.length() == 0 {
    return (FormatPart::LocField(loc=last, spec=FormatSpec::default()), input)
  }
  let (loc, rest1) = parse_digit(input)
  if rest1.length() == 0 || rest1.char_at(0) != ':' {
    if loc.is_empty() {
      return (FormatPart::LocField(loc=last, spec=FormatSpec::default()), rest1)
    } else {
      return (
        FormatPart::LocField(loc=loc.unwrap(), spec=FormatSpec::default()),
        rest1,
      )
    }
  }
  let rest2 = rest1.charcodes(start=1).trim(" ")
  let (part, rest3) = match parse_spec(rest2) {
    (spec, rest) =>
      if loc.is_empty() {
        (FormatPart::LocField(loc=last, spec~), rest)
      } else {
        (FormatPart::LocField(loc=loc.unwrap(), spec~), rest)
      }
  }
  return (part, rest3)
}

///|
fn parse_format_string(input : String) -> Array[FormatPart]!ParseError {
  let parts = Array::new()
  let mut idx = 0
  let mut last = 0
  let chars = input[:]
  let buf = StringBuilder::new()
  while idx < chars.length() {
    let c = chars.char_at(idx)
    if c == '{' {
      if idx + 1 < chars.length() && chars.char_at(idx + 1) == '{' {
        buf.write_char('{')
        idx += 2
      } else {
        if not(buf.is_empty()) {
          parts.push(FormatPart::Text(text=buf.to_string()))
          buf.reset()
        }
        let mut end = idx + 1
        let mut found = false
        while end < chars.length() {
          if chars.char_at(end) == '}' {
            found = true
            break
          }
          end += 1
        }
        if not(found) {
          raise ParseError("Unmatched '{' in format string")
        }
        let part_input = chars.charcodes(start=idx + 1, end~)
        match parse_format_part(part_input, last~) {
          (part, _) => {
            parts.push(part)
            idx = end + 1
            last += 1
          }
        }
      }
    } else if c == '}' {
      if idx + 1 < chars.length() && chars.char_at(idx + 1) == '}' {
        buf.write_char('}')
        idx += 2
      } else {
        raise ParseError("Unmatched '}' in format string")
      }
    } else {
      buf.write_char(c)
      idx += 1
    }
  }
  if not(buf.is_empty()) {
    parts.push(FormatPart::Text(text=buf.to_string()))
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
    content="{options: {fill: None, align: Left, sharp: false, zero: false}, width: None, grouping: Default, precision: 2, typ: Float}",
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
    content="{options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit}",
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
    content="LocField(loc=3, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit})",
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
    content=
      #|[LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit}), Text(text=" "), LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit}), Text(text=" "), LocField(loc=1, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit}), Text(text=" {}")]
    ,
  )
}
