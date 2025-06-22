///|
fn format_basic_type(
  spec : FormatSpec,
  value : Json,
  sb : StringBuilder
) -> Unit {
  match spec.typ {
    Float | ExponentLower | ExponentUpper | Percent =>
      align_string(spec, format_float(spec, value), sb)
    Digit | Binary | Octal | HexLower | HexUpper =>
      align_string(spec, format_digit(spec, value), sb)
    _ => abort("unexpected type in format_base_type: " + spec.typ.to_string())
  }
}

///|
pub impl Formatter for Int with display(
  self : Int,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  if spec.typ is Default {
    align_string(spec, self.to_string(), sb)
  } else {
    format_basic_type(spec, self.to_json(), sb)
  }
}

///|
pub impl Formatter for Int64 with display(
  self : Int64,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  if spec.typ is Default {
    align_string(spec, self.to_string(), sb)
  } else {
    format_basic_type(spec, self.to_json(), sb)
  }
}

///|
pub impl Formatter for Int16 with display(
  self : Int16,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  if spec.typ is Default {
    align_string(spec, self.to_string(), sb)
  } else {
    format_basic_type(spec, self.to_json(), sb)
  }
}

///|
pub impl Formatter for UInt16 with display(
  self : UInt16,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  if spec.typ is Default {
    align_string(spec, self.to_string(), sb)
  } else {
    format_basic_type(spec, self.to_json(), sb)
  }
}

///|
pub impl Formatter for UInt with display(
  self : UInt,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  if spec.typ is Default {
    align_string(spec, self.to_string(), sb)
  } else {
    format_basic_type(spec, self.to_json(), sb)
  }
}

///|
pub impl Formatter for UInt64 with display(
  self : UInt64,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  if spec.typ is Default {
    align_string(spec, self.to_string(), sb)
  } else {
    format_basic_type(spec, self.to_json(), sb)
  }
}

///|
pub impl Formatter for BigInt with display(
  self : BigInt,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  align_string(spec, self.to_string(), sb)
}

///|
pub impl Formatter for Float with display(
  self : Float,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  if spec.typ is Default {
    align_string(spec, self.to_string(), sb)
  } else {
    format_basic_type(spec, self.to_json(), sb)
  }
}

///|
pub impl Formatter for Double with display(
  self : Double,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  if spec.typ is Default {
    align_string(spec, self.to_string(), sb)
  } else {
    format_basic_type(spec, self.to_json(), sb)
  }
}

///|
pub impl Formatter for String with display(
  self : String,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  align_string(spec, self, sb)
}

///|
pub impl Formatter for Char with display(
  self : Char,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  align_string(spec, self.to_string(), sb)
}

///|
pub impl Formatter for Bool with display(
  self : Bool,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  align_string(spec, self.to_string(), sb)
}

///|
pub impl Formatter for Json with display(
  self : Json,
  spec : FormatSpec,
  sb : StringBuilder
) -> Unit {
  let value = match self {
    Json::String(s) => s
    Json::Number(n) => n.to_string()
    Json::True => "true"
    Json::False => "false"
    Json::Null => "None"
    Json::Array(arr) => arr.to_string()
    Json::Object(obj) => obj.to_string()
  }
  align_string(spec, value, sb)
}
