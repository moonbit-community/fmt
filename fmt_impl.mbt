///|
fn align_string(
  spec : FormatSpec,
  value : String,
  sb : StringBuilder,
  typ? : Typing,
) -> Unit {
  let width = spec.width.unwrap_or(0)
  let mut padding = width - value.length()
  let fill = spec.options.fill.unwrap_or(' ')
  let sharp_width = if spec.options.sharp &&
    (
      spec.typ is Binary ||
      spec.typ is Octal ||
      spec.typ is HexLower ||
      spec.typ is HexUpper
    ) {
    2
  } else {
    0
  }
  padding -= sharp_width
  let write_sharp = fn() {
    if spec.options.sharp {
      match spec.typ {
        SpecType::Binary => sb.write_string("0b")
        SpecType::Octal => sb.write_string("0o")
        SpecType::HexLower => sb.write_string("0x")
        SpecType::HexUpper => sb.write_string("0X")
        _ => ()
      }
    }
  }
  if spec.options.zero {
    if spec.options.sharp {
      write_sharp()
    }
    for _ in 0..<padding {
      sb.write_char('0')
    }
    sb.write_string(value)
    return
  }
  let align = match spec.options.align {
    Align::Left | Align::Right | Align::Center => spec.options.align
    Align::Default =>
      match typ {
        None => Align::Left
        Some(Typing::String) => Align::Left
        Some(Typing::Digit) => Align::Right
      }
  }
  match align {
    Right => {
      for _ in 0..<padding {
        sb.write_char(fill)
      }
      write_sharp()
      sb.write_string(value)
    }
    Left => {
      write_sharp()
      sb.write_string(value)
      for _ in 0..<padding {
        sb.write_char(fill)
      }
    }
    Center => {
      let left_padding = padding / 2
      let right_padding = padding - left_padding
      for _ in 0..<left_padding {
        sb.write_char(fill)
      }
      write_sharp()
      sb.write_string(value)
      for _ in 0..<right_padding {
        sb.write_char(fill)
      }
    }
    _ => panic() // unreachable
  }
}

///|
pub impl Formatter for Int with format_stream(self, spec, sb) -> Unit {
  let value = match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent =>
      self.to_double() |> format_float(spec, _)
    Digit | Binary | Octal | HexLower | HexUpper | Default =>
      self.to_int64() |> format_digit(spec, _)
  }
  align_string(spec, value, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for Int16 with format_stream(self, spec, sb) -> Unit {
  let value = match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent =>
      self.to_int().to_double() |> format_float(spec, _)
    Digit | Binary | Octal | HexLower | HexUpper | Default =>
      self.to_int64() |> format_digit(spec, _)
  }
  align_string(spec, value, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for Int64 with format_stream(self, spec, sb) -> Unit {
  let value = match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent =>
      self.to_double() |> format_float(spec, _)
    Digit | Binary | Octal | HexLower | HexUpper | Default =>
      self |> format_digit(spec, _)
  }
  align_string(spec, value, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for BigInt with format_stream(self, spec, sb) -> Unit {
  let digit = self.to_string()
  align_string(spec, digit, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for UInt with format_stream(self, spec, sb) -> Unit {
  let value = match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent =>
      self.to_double() |> format_float(spec, _)
    Digit | Binary | Octal | HexLower | HexUpper | Default =>
      self.to_int64() |> format_digit(spec, _)
  }
  align_string(spec, value, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for UInt64 with format_stream(self, spec, sb) -> Unit {
  let value = match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent =>
      self.to_int().to_double() |> format_float(spec, _)
    Digit | Binary | Octal | HexLower | HexUpper | Default =>
      self.to_int().to_int64() |> format_digit(spec, _)
  }
  align_string(spec, value, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for UInt16 with format_stream(self, spec, sb) -> Unit {
  let value = match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent =>
      self.to_int().to_double() |> format_float(spec, _)
    Digit | Binary | Octal | HexLower | HexUpper | Default =>
      self.to_int().to_int64() |> format_digit(spec, _)
  }
  align_string(spec, value, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for Float with format_stream(self, spec, sb) -> Unit {
  let value = match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent | Default =>
      self.to_double() |> format_float(spec, _)
    Digit | Binary | Octal | HexLower | HexUpper =>
      self.to_int().to_int64() |> format_digit(spec, _)
  }
  align_string(spec, value, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for Double with format_stream(self, spec, sb) -> Unit {
  let value = match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent | Default =>
      self |> format_float(spec, _)
    Digit | Binary | Octal | HexLower | HexUpper =>
      self.to_int().to_int64() |> format_digit(spec, _)
  }
  align_string(spec, value, sb, typ=Typing::Digit)
}

///|
pub impl Formatter for String with format_stream(self, spec, sb) -> Unit {
  align_string(spec, self, sb, typ=Typing::String)
}

///|
pub impl Formatter for Char with format_stream(self, spec, sb) -> Unit {
  align_string(spec, self.to_string(), sb, typ=Typing::String)
}

///|
pub impl Formatter for Bool with format_stream(self, spec, sb) -> Unit {
  align_string(spec, self.to_string(), sb, typ=Typing::String)
}

///|
pub impl Formatter for Json with format_stream(self, _spec, sb) -> Unit {
  sb.write_string(self.stringify(indent=2))
}

///|
pub impl[K : Show, V : ToJson] Formatter for Map[K, V] with format_stream(
  self,
  spec,
  sb,
) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}

///|
pub impl[T : ToJson] Formatter for Array[T] with format_stream(self, spec, sb) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}

///|
pub impl[T : ToJson] Formatter for FixedArray[T] with format_stream(
  self,
  spec,
  sb,
) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}

///|
pub impl[T : ToJson] Formatter for (T, T) with format_stream(self, spec, sb) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}

///|
pub impl[T : ToJson] Formatter for (T, T, T) with format_stream(self, spec, sb) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}

///|
pub impl[T : ToJson] Formatter for (T, T, T, T) with format_stream(
  self,
  spec,
  sb,
) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}

///|
pub impl[T : ToJson] Formatter for (T, T, T, T, T) with format_stream(
  self,
  spec,
  sb,
) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}

///|
pub impl[T : ToJson] Formatter for (T, T, T, T, T, T) with format_stream(
  self,
  spec,
  sb,
) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}

///|
pub impl[T : ToJson] Formatter for (T, T, T, T, T, T, T) with format_stream(
  self,
  spec,
  sb,
) -> Unit {
  Formatter::format_stream(self.to_json(), spec, sb)
}
