///|
typealias @string.View as Str

///|
priv enum Align {
  Left
  Right
  Center
  Default
} derive(Show)

///|
priv enum Grouping {
  Comma
  Underscore
  Default
} derive(Show)

///|
priv enum Typing {
  String
  Digit
}

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
priv struct Options {
  fill : Char?
  align : Align
  mut sharp : Bool
  mut zero : Bool
} derive(Show)

///|
impl Default for Options with default() {
  return { fill: None, align: Align::Default, sharp: false, zero: false }
}

///|
struct FormatSpec {
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
    _ => Align::Default
  }
}

///|
fn is_align_char(c : Char) -> Bool {
  return ['<', '>', '^'].contains(c)
}

///|
fn parse_fill_align(input : Str) -> (Char?, Align, Str) {
  match input {
    [any, align_c, .. input] if is_align_char(align_c) =>
      (Some(any), match_align_char(align_c), input)
    [align_c, .. chars] if is_align_char(align_c) =>
      (None, match_align_char(align_c), chars)
    [..] => (None, Default, input)
  }
}

///|
fn parse_options(input : Str) -> (Options, Str) {
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
fn parse_digit(input : Str) -> (Int?, Str) {
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
    (Some(result), input.view(start_offset=idx))
  }
}

///|
fn parse_grouping(input : Str) -> (Grouping?, Str) {
  match input {
    [',', .. chars] => return (Some(Grouping::Comma), chars)
    ['_', .. chars] => return (Some(Grouping::Underscore), chars)
    [..] => return (None, input)
  }
}

///|
fn parse_precision(input : Str) -> (Int?, Str) {
  match input {
    ['.', .. input] => {
      let (prec, rest) = parse_digit(input)
      (prec, rest)
    }
    _ => (None, input)
  }
}

///|
fn parse_type(input : Str) -> (SpecType, Str) {
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
fn parse_spec(input : Str) -> (FormatSpec, Str) {
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
    grouping: grouping.unwrap_or_default(),
    precision,
    typ,
  }
  (spec, rest5)
}

///|
fn parse_format_part(input : Str, last~ : Int) -> (FormatPart, Str) {
  let (loc, input) = parse_digit(input)
  let loc = loc.unwrap_or(last)
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
fn parse_text(input : Str) -> (String, Str) {
  let mut idx = 0
  let buf = StringBuilder::new()
  for char in input {
    if char == '{' || char == '}' {
      break
    }
    buf.write_char(char)
    idx += 1
  }
  (buf.to_string(), input.view(start_offset=idx))
}

///|
fn parse_braces(input : Str) -> (Char?, Str) {
  if input.has_prefix("{{") {
    (Some('{'), input.view(start_offset=2))
  } else if input.has_prefix("}}") {
    (Some('}'), input.view(start_offset=2))
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
        chars = new_chars.view(start_offset=1) // Skip the '}'
        last += 1
        parts.push(spec)
      }
      ['}', .. new_chars] =>
        if new_chars.has_prefix("}") {
          // This is a literal '}' in the format string
          buf.write_char('}')
          parts.push(Text(text=buf.to_string()))
          chars = new_chars.view(start_offset=1) // Skip the '}'
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
test "parse_format_string" {
  // Test simple format strings with placeholders
  inspect(
    parse_format_string("{}"),
    content="[LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default})]",
  )
  inspect(
    parse_format_string("{0}"),
    content="[LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default})]",
  )
  inspect(
    parse_format_string("{} {}"),
    content=(
      #|[LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default}), Text(text=" "), LocField(loc=1, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default})]
    ),
  )

  // Test format strings with text and placeholders
  inspect(
    parse_format_string("Hello {}, world!"),
    content=(
      #|[Text(text="Hello "), LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default}), Text(text=", world!")]
    ),
  )

  // Test format strings with specifications
  inspect(
    parse_format_string("{:d}"),
    content="[LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Digit})]",
  )
  inspect(
    parse_format_string("{0:10x}"),
    content="[LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: HexLower})]",
  )
}

///|
test "parse_format_string/escaped_braces" {
  // Test escaped braces
  inspect(
    parse_format_string("{{}}"),
    content="[Text(text=\"{\"), Text(text=\"}\")]",
  )
  inspect(
    parse_format_string("{{hello}}"),
    content=(
      #|[Text(text="{"), Text(text="hello}")]
    ),
  )
  inspect(
    parse_format_string("{{{0}}}"),
    content=(
      #|[Text(text="{"), LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default}), Text(text="}")]
    ),
  )

  // Test mixed escaped and unescaped braces
  inspect(
    parse_format_string("{{ {} }}"),
    content=(
      #|[Text(text="{"), Text(text=" "), LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default}), Text(text=" }")]
    ),
  )
}

///|
test "panic parse_format_string/unmatched_brace" {
  // Test unmatched closing brace
  ignore(parse_format_string("Hello }"))
  ignore(parse_format_string("Hello } world"))
  ignore(parse_format_string("{0} }"))
}

///|
test "parse_spec_precision" {
  let input = ".2f"
  let (spec, _) = match parse_spec(input[:]) {
    result => result
  }
  inspect(
    spec,
    content="{options: {fill: None, align: Default, sharp: false, zero: false}, width: None, grouping: Default, precision: Some(2), typ: Float}",
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
    content="{options: {fill: None, align: Default, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}",
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
    content="LocField(loc=3, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit})",
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
      #|[LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" "), LocField(loc=0, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" "), LocField(loc=1, spec={options: {fill: None, align: Default, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit}), Text(text=" {"), Text(text="}")]
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

///|
test "parse_example_13" {
  let input = "{:<#8x}"
  let result = match parse_format_string(input) {
    parts => parts
  }
  inspect(
    result,
    content="[LocField(loc=0, spec={options: {fill: None, align: Left, sharp: true, zero: false}, width: Some(8), grouping: Default, precision: None, typ: HexLower})]",
  )
}

///|
test {
  let input = "{:_d}"
  let result = match input using longest {
    re"((.?[<>=^])|([<>=^]))?([+\- ]?z?#?0?)(\d+)?([,_])?(\.(\d+))?([bcdeeEfFgGnosxX%])?" =>
      "match found"
    _ => "no match"
  }

}
