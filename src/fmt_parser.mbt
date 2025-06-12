///|
pub suberror ParseError String derive(Eq, Show)

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
  match input {
    ['#', .. chars] => ({ fill, align, sharp: true, zero: true }, chars)
    ['0', .. chars] => ({ fill, align, sharp: false, zero: true }, chars)
    [..] => ({ fill, align, sharp: false, zero: false }, input)
  }
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

//TODO : refactor this to use combinators
///|
fn parse_format_string(input : String) -> Array[FormatPart] raise ParseError {
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
          parts.push(Text(text=buf.to_string()))
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
    parts.push(Text(text=buf.to_string()))
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
    content=
      #|[LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" "), LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" "), LocField(loc=1, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" {}")]
    ,
  )
}
