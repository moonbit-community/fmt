///|
fn _align_string(spec : FormatSpec, value : String) -> String {
  let sb = StringBuilder::new()
  let width = spec.width.unwrap_or(0)
  let mut value = value
  let padding = width - value.length()
  let fill = spec.options.fill.unwrap_or(' ')
  if spec.options.zero {
    if spec.options.sharp {
      value = value.pad_start(width - 2, '0')
    } else {
      value = value.pad_start(width, '0')
    }
  }
  if spec.options.sharp {
    value = match spec.typ {
      SpecType::Binary => "0b" + value
      SpecType::Octal => "0o" + value
      SpecType::HexLower => "0x" + value
      SpecType::HexUpper => "0X" + value
      _ => value
    }
    sb.write_string(value)
    return sb.to_string()
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
  sb.to_string()
}

///|
fn format_basic_type(spec : FormatSpec, value : Json) -> String {
  match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent =>
      _align_string(spec, format_float(spec, value))
    Digit | Binary | Octal | HexLower | HexUpper =>
      _align_string(spec, format_digit(spec, value))
    _ => abort("unexpected type in format_base_type: " + spec.typ.to_string())
  }
}

///|
pub impl Formatter for Int with format(self : Int, spec : FormatSpec) -> String {
  if spec.typ is Default {
    _align_string(spec, self.to_string())
  } else {
    format_basic_type(spec, self.to_json())
  }
}

///|
pub impl Formatter for Int64 with format(self : Int64, spec : FormatSpec) -> String {
  if spec.typ is Default {
    _align_string(spec, self.to_string())
  } else {
    format_basic_type(spec, self.to_json())
  }
}

///|
pub impl Formatter for Int16 with format(self : Int16, spec : FormatSpec) -> String {
  if spec.typ is Default {
    _align_string(spec, self.to_string())
  } else {
    format_basic_type(spec, self.to_json())
  }
}

///|
pub impl Formatter for UInt16 with format(self : UInt16, spec : FormatSpec) -> String {
  if spec.typ is Default {
    _align_string(spec, self.to_string())
  } else {
    format_basic_type(spec, self.to_json())
  }
}

///|
pub impl Formatter for UInt with format(self : UInt, spec : FormatSpec) -> String {
  if spec.typ is Default {
    _align_string(spec, self.to_string())
  } else {
    format_basic_type(spec, self.to_json())
  }
}

///|
pub impl Formatter for UInt64 with format(self : UInt64, spec : FormatSpec) -> String {
  if spec.typ is Default {
    _align_string(spec, self.to_string())
  } else {
    format_basic_type(spec, self.to_json())
  }
}

///|
pub impl Formatter for BigInt with format(self : BigInt, spec : FormatSpec) -> String {
  _align_string(spec, self.to_string())
}

///|
pub impl Formatter for Float with format(self : Float, spec : FormatSpec) -> String {
  if spec.typ is Default {
    _align_string(spec, self.to_string())
  } else {
    format_basic_type(spec, self.to_json())
  }
}

///|
pub impl Formatter for Double with format(self : Double, spec : FormatSpec) -> String {
  if spec.typ is Default {
    _align_string(spec, self.to_string())
  } else {
    format_basic_type(spec, self.to_json())
  }
}

///|
pub impl Formatter for String with format(self : String, spec : FormatSpec) -> String {
  _align_string(spec, self)
}

///|
pub impl Formatter for Char with format(self : Char, spec : FormatSpec) -> String {
  _align_string(spec, self.to_string())
}

///|
pub impl Formatter for Bool with format(self : Bool, spec : FormatSpec) -> String {
  _align_string(spec, self.to_string())
}

///|
pub impl Formatter for Json with format(self : Json, spec : FormatSpec) -> String {
  let value = match self {
    Json::String(s) => s
    Json::Number(n, ..) => n.to_string()
    Json::True => "true"
    Json::False => "false"
    Json::Null => "None"
    Json::Array(arr) => arr.to_string()
    Json::Object(obj) => obj.to_string()
  }
  _align_string(spec, value)
}
