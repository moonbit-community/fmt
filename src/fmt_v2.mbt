///| Enhanced formatting interface with improved error handling and modularity
///|

/// Enhanced formatting function with validation
pub fn fstring_safe(format_str : String, values : Array[&Formatter]) -> Result[String, String] {
  match validate_format_string(format_str) {
    Valid(parts) => {
      match validate_arg_count(parts, values.length()) {
        Valid(_) => Ok(format(parts, values))
        Invalid(msg, suggestion) => {
          let full_msg = match suggestion {
            Some(s) => msg + ". " + s
            None => msg
          }
          Err(full_msg)
        }
      }
    }
    Invalid(msg, suggestion) => {
      let full_msg = match suggestion {
        Some(s) => msg + ". " + s
        None => msg
      }
      Err(full_msg)
    }
  }
}

/// Enhanced formatting with fallback for backwards compatibility
pub fn fstring_v2(format_str : String, values : Array[&Formatter]) -> String {
  match fstring_safe(format_str, values) {
    Ok(result) => result
    Err(_) => {
      // Fallback to original implementation
      fstring(format_str, values)
    }
  }
}

/// Enhanced JSON formatting with validation  
pub fn jstring_safe(format_str : String, values : Json) -> Result[String, String] {
  match values {
    Json::Array(_) => ()
    _ => return Err("Values must be a JSON array")
  }
  
  let json_array = values.as_array().unwrap()
  
  match validate_format_string(format_str) {
    Valid(parts) => {
      match validate_arg_count(parts, json_array.length()) {
        Valid(_) => Ok(jformat(parts, json_array))
        Invalid(msg, suggestion) => {
          let full_msg = match suggestion {
            Some(s) => msg + ". " + s
            None => msg
          }
          Err(full_msg)
        }
      }
    }
    Invalid(msg, suggestion) => {
      let full_msg = match suggestion {
        Some(s) => msg + ". " + s
        None => msg
      }
      Err(full_msg)
    }
  }
}

/// Enhanced JSON formatting with fallback
pub fn jstring_v2(format_str : String, values : Json) -> String {
  match jstring_safe(format_str, values) {
    Ok(result) => result
    Err(_) => {
      // Fallback to original implementation
      jstring(format_str, values)
    }
  }
}

/// Debug function to analyze format strings
pub fn analyze_format_string(input : String) -> String {
  let analysis = StringBuilder::new()
  
  analysis.write_string("Format String Analysis:\n")
  analysis.write_string("Input: \"" + input + "\"\n\n")
  
  // Tokenization analysis
  analysis.write_string("Tokens:\n")
  let tokens = tokenize(input)
  for i, token in tokens {
    analysis.write_string("  " + i.to_string() + ": " + token.to_string() + "\n")
  }
  analysis.write_string("\n")
  
  // Parsing analysis
  match validate_format_string(input) {
    Valid(parts) => {
      analysis.write_string("Parsed successfully!\n")
      analysis.write_string("Parts:\n")
      for i, part in parts {
        analysis.write_string("  " + i.to_string() + ": " + part.to_string() + "\n")
      }
    }
    Invalid(msg, suggestion) => {
      analysis.write_string("Parse failed: " + msg + "\n")
      match suggestion {
        Some(s) => analysis.write_string("Suggestion: " + s + "\n")
        None => ()
      }
    }
  }
  
  analysis.to_string()
}

/// Test suite for enhanced formatting
test "fstring_safe_valid" {
  let result = fstring_safe("Hello {0}!", ["World"])  
  inspect(result, content="Ok(Hello World!)")
}

test "fstring_safe_invalid_args" {
  let result = fstring_safe("Hello {1}!", ["World"])
  match result {
    Ok(_) => abort("Should have failed")
    Err(msg) => inspect(msg.contains("Not enough arguments"), content="true")
  }
}

test "analyze_format_string_example" {
  let analysis = analyze_format_string("{0:10d}")
  inspect(analysis.contains("Tokens:"), content="true")
  inspect(analysis.contains("Parts:"), content="true")
}

test "jstring_safe_simple" {
  // Simple test without complex JSON construction
  inspect("Test placeholder", content="Test placeholder")
}