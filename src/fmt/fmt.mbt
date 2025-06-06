///|
enum FormatPart {
  Digit(fill~ : Char, width~ : Int)
  String(fill~ : Char, width~ : Int)
  Float(fill~ : Char, width~ : Int, precision~ : Int)
  Other
}

///|
pub fn format_part(part : FormatPart, value : Json) -> String {
  match (part, value) {
    (FormatPart::Digit(fill~, width~), Json::Number(num)) =>
      num.to_string().pad_start(width, fill)
    (FormatPart::String(fill~, width~), Json::String(s)) => {
      let padded_value = s.pad_start(width, fill)
      padded_value
    }
    (FormatPart::Float(..), Json::Number(num)) => num.to_string()
    (FormatPart::Other, Json::Object(map)) => map.to_string()
    (_, _) => abort("Unsupported format part or value type")
  }
}

///|
pub fn format(parts : Array[FormatPart], values : Json) -> String {
  let result = StringBuilder::new()
  match values {
    Array(_) => ()
    _ => abort("format expects an array of values")
  }
  let values = values.as_array().unwrap()
  guard values.length() == parts.length() else {
    abort("format expects the same number of values as parts")
  }
  for idx in 0..<parts.length() {
    let part = parts[idx]
    let value = values[idx]
    let formatted_value = format_part(part, value)
    result.write_string(formatted_value)

    // Add a space after each part except the last one
    if idx < parts.length() - 1 {
      result.write_string(" ")
    }
  }
  result.to_string()
}

///|
pub fn fprintln(parts : Array[FormatPart], values : Json) -> Unit {
  let formatted_string = format(parts, values)
  println(formatted_string)
}

///|
struct TestObj {
  name : String
  age : Int
} derive(ToJson, FromJson)

///|
test "format with digit" {
  let parts = [FormatPart::Digit(fill='0', width=5), FormatPart::Other]
  fprintln(parts, [1, { name: "Alice", age: 30 }])
}
