///| Main format string parser that combines lexer and parser components
///|

/// State for keeping track of auto-numbered placeholders
struct ParserState {
  mut auto_index : Int
}

/// Create a new parser state
fn new_parser_state() -> ParserState {
  { auto_index: 0 }
}

/// Parse a format placeholder from tokens
fn parse_field(tokens : Array[Token], idx : Int, state : ParserState) -> (FormatPart, Int) {
  // Expect: Number? Colon? FormatSpec? RightBrace
  let mut loc = state.auto_index
  let mut spec = FormatSpec::default()
  let mut current_idx = idx
  
  // Check for explicit index
  if current_idx < tokens.length() {
    match tokens[current_idx] {
      Token::Number(n) => {
        loc = n
        current_idx += 1
      }
      _ => {
        state.auto_index += 1
      }
    }
  }
  
  // Check for format specification
  if current_idx < tokens.length() {
    match tokens[current_idx] {
      Token::Colon => {
        current_idx += 1
        // Parse format specification from remaining tokens
        let spec_tokens = Array::new()
        while current_idx < tokens.length() {
          match tokens[current_idx] {
            Token::RightBrace => break
            token => {
              spec_tokens.push(token)
              current_idx += 1
            }
          }
        }
        
        // Convert tokens back to string for spec parsing
        let spec_string = tokens_to_string(spec_tokens)
        let (parsed_spec, _) = parse_spec(spec_string[:])
        spec = parsed_spec
      }
      _ => () // Use default spec
    }
  }
  
  // Expect right brace
  if current_idx < tokens.length() {
    match tokens[current_idx] {
      Token::RightBrace => current_idx += 1
      _ => abort("Expected closing brace")
    }
  }
  
  (LocField(loc~, spec~), current_idx)
}

/// Convert tokens back to string (for format spec parsing)
fn tokens_to_string(tokens : Array[Token]) -> String {
  let result = StringBuilder::new()
  
  for token in tokens {
    match token {
      Token::Text(s) => result.write_string(s)
      Token::Number(n) => result.write_string(n.to_string())
      Token::FormatChar(c) => result.write_char(c)
      Token::Colon => result.write_char(':')
      Token::LeftBrace => result.write_char('{')
      Token::RightBrace => result.write_char('}')
      _ => () // Skip other tokens
    }
  }
  
  result.to_string()
}

/// Parse tokens into format parts
fn parse_tokens(tokens : Array[Token]) -> Array[FormatPart] {
  let parts = Array::new()
  let state = new_parser_state()
  let mut idx = 0
  
  while idx < tokens.length() {
    match tokens[idx] {
      Token::Text(text) => {
        parts.push(FormatPart::Text(text~))
        idx += 1
      }
      Token::LeftBrace => {
        idx += 1
        let (field, new_idx) = parse_field(tokens, idx, state)
        parts.push(field)
        idx = new_idx
      }
      _ => {
        // Unexpected token, treat as text
        idx += 1
      }
    }
  }
  
  parts
}

/// Enhanced format string parser with better error handling
pub fn parse_format_string_v2(input : String) -> Result[Array[FormatPart], String] {
  let tokens = tokenize(input)
  let parts = parse_tokens(tokens)
  Ok(parts)
}

/// Fallback to the original parser for compatibility
pub fn parse_format_string_safe(input : String) -> Array[FormatPart] {
  match parse_format_string_v2(input) {
    Ok(parts) => parts
    Err(_) => {
      // Fall back to original parser
      parse_format_string(input)
    }
  }
}

/// Test suite for enhanced parser
test "enhanced_parser_simple" {
  let result = parse_format_string_v2("Hello {0}")
  inspect(result, content="Ok([Text(\"Hello \"), LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default})])")
}

test "enhanced_parser_with_spec" {
  let result = parse_format_string_v2("{0:10d}")
  inspect(result, content="Ok([LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: Some(10), grouping: Default, precision: None, typ: Digit})])")
}

test "enhanced_parser_auto_numbering" {
  let result = parse_format_string_v2("{} {}")
  inspect(result, content="Ok([LocField(loc=0, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default}), Text(\" \"), LocField(loc=1, spec={options: {fill: None, align: Left, sharp: false, zero: false}, width: None, grouping: Default, precision: None, typ: Default})])")
}