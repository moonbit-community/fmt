type! ParseError String

typealias @string.View as str

pub fn tag(tag: String) -> (str) -> Result[str, ParseError] {
  fn (input: str) -> Result[str, ParseError] {
    if input.has_prefix(tag) {
      let len = input.offset_of_nth_char(tag.length()).unwrap()
      Ok(input.charcodes(start=len))
    } else {
      Err(ParseError("Tag not found: " + tag))
    }
  }
}

