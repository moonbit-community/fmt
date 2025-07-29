///| Core parser types and utilities - simplified version
///|
typealias @string.View as str

/// A result type for parser operations
pub enum ParseResult[T] {
  Ok(T, str)
  Error(String)
} derive(Show, Eq)

/// Parser error information
pub enum ParseError {
  UnexpectedChar(Char, String)
  UnexpectedEof(String)
  InvalidNumber(String)
  UnmatchedBrace(String)
} derive(Show, Eq)

/// Convert a ParseError to a string
fn parse_error_to_string(error : ParseError) -> String {
  match error {
    UnexpectedChar(char, expected) => 
      "Unexpected character '" + char.to_string() + "', expected " + expected
    UnexpectedEof(expected) => 
      "Unexpected end of input, expected " + expected
    InvalidNumber(msg) => 
      "Invalid number: " + msg
    UnmatchedBrace(msg) => 
      "Unmatched brace: " + msg
  }
}

/// Create an Ok result
pub fn ok[T](value : T, remaining : str) -> ParseResult[T] {
  ParseResult::Ok(value, remaining)
}

/// Create an Error result
pub fn error[T](msg : String) -> ParseResult[T] {
  ParseResult::Error(msg)
}