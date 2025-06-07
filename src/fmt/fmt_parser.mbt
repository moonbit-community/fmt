///|
type! ParseError String derive(Eq, Show)

///|
typealias @string.View as str

///|
enum Align {
  Left
  Right
  Center
} derive(Show, Eq)

///|
enum Sign {
  Plus
  Minus
  Space
} derive(Show)

///|
enum Grouping {
  Comma
  Underscore
  Default
} derive(Show)

///|
impl Default for Grouping with default() {
  return Grouping::Default
}

///|
enum SpecType {
  Binary
  Char
  Digit
  ExponentLower
  ExponentUpper
  Float
  Octal
  String
  HexLower
  HexUpper
  Default
} derive(Show)

///|
impl Default for SpecType with default() {
  return SpecType::Default
}

///|
struct Options {
  fill : Char?
  align : Align
  sign : Sign?
  z : Bool
  sharp : Bool
  zero : Bool
} derive(Show)

///|
fn Options::is_empty(self : Options) -> Bool {
  return self.fill.is_empty() &&
    self.align == Align::Left &&
    self.sign.is_empty() &&
    not(self.z) &&
    not(self.sharp) &&
    not(self.zero)
}

///|
impl Default for Options with default() {
  return {
    fill: None,
    align: Align::Left,
    sign: None,
    z: false,
    sharp: false,
    zero: false,
  }
}

///|
struct FormatSpec {
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
fn parse_options(input : str) -> Result[(Options, str), ParseError] {
  let mut fill : Char? = None
  let mut align : Align = Left
  let mut sign : Sign? = None
  let mut z = false
  let mut sharp = false
  let mut zero = false
  let mut idx = 0
  if input.length() > idx + 1 {
    let next = input.char_at(idx + 1)
    match next {
      '<' | '>' | '^' => {
        fill = Some(input.char_at(idx))
        align = match next {
          '<' => Align::Left
          '>' => Align::Right
          '^' => Align::Center
          _ => Align::Left
        }
        idx += 2
      }
      _ => ()
    }
  }
  if fill.is_empty() && input.length() > idx {
    match input.char_at(idx) {
      '<' => {
        align = Align::Left
        idx += 1
      }
      '>' => {
        align = Align::Right
        idx += 1
      }
      '^' => {
        align = Align::Center
        idx += 1
      }
      _ => ()
    }
  }

  // [sign]
  if input.length() > idx {
    match input.char_at(idx) {
      '+' => {
        sign = Some(Sign::Plus)
        idx += 1
      }
      '-' => {
        sign = Some(Sign::Minus)
        idx += 1
      }
      ' ' => {
        sign = Some(Sign::Space)
        idx += 1
      }
      _ => ()
    }
  }

  // ["z"]["#"]["0"]
  while input.length() > idx {
    match input.char_at(idx) {
      'z' => {
        z = true
        idx += 1
      }
      '#' => {
        sharp = true
        idx += 1
      }
      '0' => {
        zero = true
        idx += 1
      }
      _ => break
    }
  }
  let options = { fill, align, sign, z, sharp, zero }
  if options.is_empty() {
    return Ok((options, input))
  }
  Ok((options, input.charcodes(start=idx)))
}

///|
fn parse_digit(input : str) -> Result[(Int?, str), ParseError] {
  let mut idx = 0
  while input.length() > idx && input.char_at(idx).is_digit(10) {
    // println(input.char_at(idx))
    idx += 1
  }
  if idx == 0 {
    Ok((None, input))
  } else {
    let width_str = input.charcodes(start=0, end=idx).to_string()
    let result = try? @strconv.parse_int(width_str, base=10)
    // println(result)
    match result {
      Ok(width) => Ok((Some(width), input.charcodes(start=idx)))
      Err(_) => Err(ParseError("Invalid digit: " + width_str))
    }
  }
}

///|
fn parse_grouping(input : str) -> Result[(Grouping?, str), ParseError] {
  if input.length() == 0 {
    return Ok((None, input))
  }
  match input.char_at(0) {
    ',' => Ok((Some(Grouping::Comma), input.charcodes(start=1)))
    '_' => Ok((Some(Grouping::Underscore), input.charcodes(start=1)))
    _ => Ok((None, input))
  }
}

///|
fn parse_precision(input : str) -> Result[(Int?, str), ParseError] {
  if input.length() > 0 && input.char_at(0) == '.' {
    let rest = input.charcodes(start=1)
    let result = parse_digit(rest)
    match result {
      Ok((Some(prec), rest2)) => return Ok((Some(prec), rest2))
      Ok((None, rest2)) => return Ok((None, rest2))
      Err(e) => return Err(e)
    }
  } else {
    Ok((None, input))
  }
}

///|
fn parse_type(input : str) -> Result[(SpecType, str), ParseError] {
  if input.length() == 0 {
    return Ok((SpecType::Default, input))
  }
  match input.char_at(0) {
    'b' => Ok((SpecType::Binary, input.charcodes(start=1)))
    'c' => Ok((SpecType::Char, input.charcodes(start=1)))
    'd' => Ok((SpecType::Digit, input.charcodes(start=1)))
    'e' => Ok((SpecType::ExponentLower, input.charcodes(start=1)))
    'E' => Ok((SpecType::ExponentUpper, input.charcodes(start=1)))
    'f' => Ok((SpecType::Float, input.charcodes(start=1)))
    'o' => Ok((SpecType::Octal, input.charcodes(start=1)))
    's' => Ok((SpecType::String, input.charcodes(start=1)))
    'x' => Ok((SpecType::HexLower, input.charcodes(start=1)))
    'X' => Ok((SpecType::HexUpper, input.charcodes(start=1)))
    _ => Ok((SpecType::Default, input))
  }
}

///|
fn parse_spec(input : str) -> Result[(FormatSpec, str), ParseError] {
  // 1. options
  let (options, rest1) = match parse_options(input) {
    Ok((options, rest1)) => (options, rest1)
    Err(e) => return Err(e)
  }

  // 2. width
  let (width, rest2) = match parse_digit(rest1) {
    Ok((width, rest)) => (width, rest)
    Err(e) => return Err(e)
  }

  // 3. grouping
  let (grouping, rest3) = match parse_grouping(rest2) {
    Ok((grouping, rest)) => (grouping, rest)
    Err(e) => return Err(e)
  }

  // 4. precision
  let (precision, rest4) = match parse_precision(rest3) {
    Ok((precision, rest)) => (precision, rest)
    Err(e) => return Err(e)
  }
  // 5. type
  let (typ, rest5) = match parse_type(rest4) {
    Ok((typ, rest)) => (typ, rest)
    Err(e) => return Err(e)
  }
  let spec = {
    options,
    width,
    grouping: grouping.or_default(),
    precision: precision.or(6),
    typ,
  }
  Ok((spec, rest5))
}

///|
fn parse_format_part(
  input : str,
  last~ : Int
) -> Result[(FormatPart, str), ParseError] {
  let input = input.trim(" ")
  if input.length() == 0 {
    return Ok(
      (FormatPart::LocField(loc=last, spec=FormatSpec::default()), input),
    )
  }
  let (loc, rest1) = match parse_digit(input) {
    Ok((width, rest)) => (width, rest)
    Err(_) => (None, input)
  }
  if rest1.length() == 0 || rest1.char_at(0) != ':' {
    if loc.is_empty() {
      return Ok(
        (FormatPart::LocField(loc=last, spec=FormatSpec::default()), rest1),
      )
    } else {
      return Ok(
        (
          FormatPart::LocField(loc=loc.unwrap(), spec=FormatSpec::default()),
          rest1,
        ),
      )
    }
  }
  let rest2 = rest1.charcodes(start=1).trim(" ")
  let (part, rest3) = match parse_spec(rest2) {
    Ok((spec, rest)) =>
      if loc.is_empty() {
        (FormatPart::LocField(loc=last, spec~), rest)
      } else {
        (FormatPart::LocField(loc=loc.unwrap(), spec~), rest)
      }
    Err(e) => return Err(e)
  }
  return Ok((part, rest3))
}

///|
fn parse_format_string(input : String) -> Result[Array[FormatPart], ParseError] {
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
          return Err(ParseError("Unmatched '{' in format string"))
        }
        let part_input = chars.charcodes(start=idx + 1, end~)
        match parse_format_part(part_input, last~) {
          Ok((part, _)) => {
            parts.push(part)
            idx = end + 1
            last += 1
          }
          Err(e) => return Err(e)
        }
      }
    } else if c == '}' {
      if idx + 1 < chars.length() && chars.char_at(idx + 1) == '}' {
        buf.write_char('}')
        idx += 2
      } else {
        return Err(ParseError("Unmatched '}' in format string"))
      }
    } else {
      buf.write_char(c)
      idx += 1
    }
  }
  if not(buf.is_empty()) {
    parts.push(FormatPart::Text(text=buf.to_string()))
  }
  Ok(parts)
}

///|
test "parse_spec_precision" {
  let input = ".2f"
  let (spec, _) = match parse_spec(input[:]) {
    Err(err) => {
      println(err.to_string())
      abort(err.to_string())
    }
    Ok(result) => result
  }
  inspect(
    spec,
    content="{options: {fill: None, align: Left, sign: None, z: false, sharp: false, zero: false}, width: None, grouping: Default, precision: 2, typ: Float}",
  )
}

///|
test "parse_spec_width" {
  let input = "10d"
  let (spec, _) = match parse_spec(input[:]) {
    Err(err) => {
      println(err.to_string())
      abort(err.to_string())
    }
    Ok(result) => result
  }
  inspect(
    spec,
    content="{options: {fill: None, align: Left, sign: None, z: false, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit}",
  )
}

///|
test "parse_format_part" {
  let input = "3:10d"
  let (part, rest) = match parse_format_part(input[:], last=0) {
    Ok(result) => result
    Err(e) => abort(e.to_string())
  }
  inspect(
    part,
    content="LocField(loc=3, spec={options: {fill: None, align: Left, sign: None, z: false, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit})",
  )
  inspect(rest, content="")
}

///|
test "parse_fmt_string" {
  let input = "{:10d} {0:10d} {1:10d} {{}}"
  let result = match parse_format_string(input) {
    Ok(parts) => parts
    Err(e) => abort(e.to_string())
  }
  inspect(
    result,
    content=
      #|[LocField(loc=0, spec={options: {fill: None, align: Left, sign: None, z: false, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit}), Text(text=" "), LocField(loc=0, spec={options: {fill: None, align: Left, sign: None, z: false, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit}), Text(text=" "), LocField(loc=1, spec={options: {fill: None, align: Left, sign: None, z: false, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: 6, typ: Digit}), Text(text=" {}")]
    ,
  )
}
