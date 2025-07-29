///| Lexer for format strings - tokenizes input into meaningful parts
///|

/// Token types for format string parsing
pub enum Token {
  Text(String)
  LeftBrace
  RightBrace
  Colon
  Number(Int)
  FormatChar(Char)
  Eof
} derive(Show, Eq)

/// Lexer state
pub struct Lexer {
  input : str
  mut position : Int
  mut current_char : Char?
}

/// Create a new lexer
pub fn new_lexer(input : String) -> Lexer {
  let lexer = { input: input[:], position: 0, current_char: None }
  advance_lexer(lexer)
  lexer
}

/// Advance to the next character
fn advance_lexer(lexer : Lexer) -> Unit {
  if lexer.position >= lexer.input.length() {
    lexer.current_char = None
  } else {
    match lexer.input {
      input => {
        let mut idx = 0
        for c in input {
          if idx == lexer.position {
            lexer.current_char = Some(c)
            break
          }
          idx += 1
        }
      }
    }
  }
  lexer.position += 1
}

/// Peek at the next character without advancing
fn peek_lexer(lexer : Lexer) -> Char? {
  if lexer.position >= lexer.input.length() {
    None
  } else {
    let mut idx = 0
    let mut result = None
    for c in lexer.input {
      if idx == lexer.position {
        result = Some(c)
        break
      }
      idx += 1
    }
    result
  }
}

/// Skip whitespace characters
fn skip_whitespace(lexer : Lexer) -> Unit {
  while true {
    match lexer.current_char {
      Some(' ') | Some('\t') | Some('\n') | Some('\r') => advance_lexer(lexer)
      _ => break
    }
  }
}

/// Read a number token
fn read_number(lexer : Lexer) -> Int {
  let mut result = 0
  
  while true {
    match lexer.current_char {
      Some(c) if c.is_digit(10) => {
        result = result * 10 + (Char::to_int(c) - Char::to_int('0'))
        advance_lexer(lexer)
      }
      _ => break
    }
  }
  
  result
}

/// Read a text token until we hit a brace or end of input
fn read_text(lexer : Lexer) -> String {
  let buffer = StringBuilder::new()
  
  while true {
    match lexer.current_char {
      Some('{') | Some('}') | None => break
      Some(c) => {
        buffer.write_char(c)
        advance_lexer(lexer)
      }
    }
  }
  
  buffer.to_string()
}

/// Get the next token from the input
pub fn next_token(lexer : Lexer) -> Token {
  match lexer.current_char {
    None => Token::Eof
    Some('{') => {
      advance_lexer(lexer)
      if lexer.current_char == Some('{') {
        // Escaped left brace
        advance_lexer(lexer)
        Token::Text("{")
      } else {
        Token::LeftBrace
      }
    }
    Some('}') => {
      advance_lexer(lexer)
      if lexer.current_char == Some('}') {
        // Escaped right brace  
        advance_lexer(lexer)
        Token::Text("}")
      } else {
        Token::RightBrace
      }
    }
    Some(':') => {
      advance_lexer(lexer)
      Token::Colon
    }
    Some(c) if c.is_digit(10) => {
      Token::Number(read_number(lexer))
    }
    Some(c) if c.is_ascii_alphabetic() => {
      advance_lexer(lexer)
      Token::FormatChar(c)
    }
    _ => {
      // Read regular text
      let text = read_text(lexer)
      if text.is_empty() {
        advance_lexer(lexer) // Skip unknown character
        next_token(lexer)    // Try next token
      } else {
        Token::Text(text)
      }
    }
  }
}

/// Tokenize the entire input into a list of tokens
pub fn tokenize(input : String) -> Array[Token] {
  let lexer = new_lexer(input)
  let tokens = Array::new()
  
  while true {
    let token = next_token(lexer)
    if token == Token::Eof {
      break
    }
    tokens.push(token)
  }
  
  tokens
}

/// Test suite for lexer
test "lexer_simple_text" {
  let tokens = tokenize("hello world")
  inspect(tokens, content="[Text(hello world)]")
}

test "lexer_with_braces" {
  let tokens = tokenize("Hello {0}")
  inspect(tokens, content="[Text(Hello ), LeftBrace, Number(0), RightBrace]")
}

test "lexer_escaped_braces" {
  let tokens = tokenize("Hello {{world}}")
  inspect(tokens, content="[Text(Hello ), Text({), Text(world), Text(})]")
}

test "lexer_with_format_spec" {
  let tokens = tokenize("{0:d}")
  inspect(tokens, content="[LeftBrace, Number(0), Colon, FormatChar('d'), RightBrace]")
}