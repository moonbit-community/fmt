///| Error handling utilities for the format parsing system
///|

/// Validation result for format operations
pub enum ValidationResult[T] {
  Valid(T)
  Invalid(String, String?)
} derive(Show, Eq)

/// Format-specific errors
pub enum FormatError {
  InvalidPlaceholder(Int, String)
  MissingArgument(Int)
  TypeMismatch(String, String)
  SpecificationError(String, String)
} derive(Show, Eq)

/// Convert format error to user-friendly message
pub fn format_error_message(error : FormatError) -> String {
  match error {
    InvalidPlaceholder(pos, reason) =>
      "Invalid placeholder at position " + pos.to_string() + ": " + reason
    MissingArgument(index) =>
      "Missing argument for placeholder " + index.to_string()
    TypeMismatch(expected, got) =>
      "Type mismatch: expected " + expected + ", got " + got
    SpecificationError(spec, reason) =>
      "Invalid format specification '" + spec + "': " + reason
  }
}

/// Validate format string arguments count
pub fn validate_arg_count(parts : Array[FormatPart], arg_count : Int) -> ValidationResult[Unit] {
  let mut max_index = -1
  
  for part in parts {
    match part {
      LocField(loc~, spec~) => {
        if loc > max_index {
          max_index = loc
        }
      }
      _ => ()
    }
  }
  
  if max_index >= arg_count {
    Invalid(
      "Not enough arguments: expected at least " + (max_index + 1).to_string() + 
      ", got " + arg_count.to_string(),
      Some("Add more arguments or use lower indices")
    )
  } else {
    Valid(())
  }
}

/// Validate format specification compatibility with value type
pub fn validate_spec_compatibility(spec : FormatSpec, value_type : String) -> ValidationResult[Unit] {
  match (spec.typ, value_type) {
    (Binary | Octal | HexLower | HexUpper | Digit, "number") => Valid(())
    (Float | ExponentLower | ExponentUpper | Percent, "number") => Valid(())
    (Default, _) => Valid(())
    (typ, vtype) =>
      Invalid(
        "Format type " + typ.to_string() + " is not compatible with " + vtype,
        Some("Use a compatible format type or change the value type")
      )
  }
}

/// Recovery strategies for parse errors
pub enum RecoveryStrategy {
  SkipToNext
  UseDefault(FormatPart)
  TreatAsText(String)
} derive(Show)

/// Attempt to recover from a parse error
pub fn suggest_recovery(error : String, context : str) -> RecoveryStrategy {
  if error.contains("Unmatched") {
    // Try to treat the problematic part as literal text
    TreatAsText(context.to_string())
  } else if error.contains("Invalid number") {
    // Use a default placeholder
    UseDefault(LocField(loc=0, spec=FormatSpec::default()))
  } else {
    // Skip to the next valid part
    SkipToNext
  }
}

/// Comprehensive format string validation
pub fn validate_format_string(input : String) -> ValidationResult[Array[FormatPart]] {
  match parse_format_string_v2(input) {
    Ok(parts) => {
      // Additional validations can be added here
      // For example, checking for well-formed braces
      Valid(parts)
    }
    Err(msg) => {
      let suggestion = if msg.contains("brace") {
        Some("Check that all braces are properly matched and escaped")
      } else if msg.contains("number") {
        Some("Ensure all placeholder numbers are valid integers")  
      } else {
        Some("Check the format string syntax")
      }
      Invalid(msg, suggestion)
    }
  }
}

/// Test suite for error handling
test "validate_arg_count_sufficient" {
  let parts = [LocField(loc=0, spec=FormatSpec::default()), LocField(loc=1, spec=FormatSpec::default())]
  let result = validate_arg_count(parts, 3)
  inspect(result, content="Valid(())")
}

test "validate_arg_count_insufficient" {
  let parts = [LocField(loc=2, spec=FormatSpec::default())]
  let result = validate_arg_count(parts, 2)
  inspect(result, content="Invalid(Not enough arguments: expected at least 3, got 2, suggestion=Some(Add more arguments or use lower indices))")
}

test "validate_spec_compatibility_valid" {
  let spec = { options: Options::default(), width: None, grouping: Grouping::Default, precision: None, typ: SpecType::Digit }
  let result = validate_spec_compatibility(spec, "number")
  inspect(result, content="Valid(())")
}

test "validate_spec_compatibility_invalid" {
  let spec = { options: Options::default(), width: None, grouping: Grouping::Default, precision: None, typ: SpecType::Binary }
  let result = validate_spec_compatibility(spec, "string")
  inspect(result, content="Invalid(Format type Binary is not compatible with string, suggestion=Some(Use a compatible format type or change the value type))")
}