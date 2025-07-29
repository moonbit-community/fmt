# Format Library Architecture Documentation

## Overview

The MoonBit format library has been refactored to provide better modularity, improved error handling, and enhanced functionality while maintaining backward compatibility.

## Architecture

### Module Structure

The library is now organized into focused modules:

1. **`parser_core.mbt`** - Core parser types and result handling
2. **`lexer.mbt`** - Tokenization of format strings 
3. **`spec_parser.mbt`** - Format specification parsing logic
4. **`format_parser.mbt`** - Main format string parsing orchestration
5. **`error_handling.mbt`** - Validation and error reporting utilities
6. **`fmt_parser.mbt`** - Original parser (maintained for compatibility)
7. **`fmt.mbt`** - Core formatting functions (original API)
8. **`fmt_v2.mbt`** - Enhanced API with improved error handling
9. **`fmt_impl.mbt`** - Type-specific formatter implementations
10. **`types.mbt`** - Core type definitions and traits

### Key Improvements

#### 1. Enhanced Error Handling
- **Safe API**: Functions like `fstring_safe()` return `Result<String, String>` for explicit error handling
- **Validation**: Input validation with detailed error messages and suggestions
- **Fallback**: Enhanced functions automatically fall back to original implementation on failure

#### 2. Better Modularity
- **Separation of Concerns**: Lexing, parsing, and validation are in separate modules
- **Parser Combinators**: Foundation for composable parsing (in `parser_core.mbt`)
- **Focused Responsibilities**: Each module has a clear, single responsibility

#### 3. Improved Type Safety
- **Result Types**: Explicit error handling through Result types
- **Validation**: Runtime validation of arguments and format specifications
- **Strong Typing**: Better type annotations and constraints

#### 4. Performance Optimizations
- **Reduced Allocations**: More efficient string handling
- **Optimized Parsing**: Streamlined parsing workflows
- **Caching Potential**: Architecture supports future caching additions

## API Reference

### Original API (Maintained)
- `fstring(String, Array[&Formatter]) -> String`
- `fprintln(String, Array[&Formatter]) -> Unit`
- `jstring(String, Json) -> String`
- `jprintln(String, Json) -> Unit`

### Enhanced API (New)
- `fstring_safe(String, Array[&Formatter]) -> Result[String, String]`
- `fstring_v2(String, Array[&Formatter]) -> String` (with fallback)
- `jstring_safe(String, Json) -> Result[String, String]`
- `jstring_v2(String, Json) -> String` (with fallback)
- `analyze_format_string(String) -> String` (debugging tool)

### Core Types

#### `FormatSpec`
```moonbit
pub struct FormatSpec {
  options : Options
  width : Int?
  grouping : Grouping
  precision : Int?
  typ : SpecType
}
```

#### `ValidationResult[T]`
```moonbit
pub enum ValidationResult[T] {
  Valid(T)
  Invalid(String, String?) // message, suggestion
}
```

#### `ParseResult[T]`
```moonbit
pub enum ParseResult[T] {
  Ok(T, str) // value, remaining input
  Error(String)
}
```

## Usage Examples

### Basic Usage (Original API)
```moonbit
let result = fstring("Hello {0}!", ["World"])
// result: "Hello World!"
```

### Safe Usage (Enhanced API)
```moonbit
match fstring_safe("Hello {0}!", ["World"]) {
  Ok(result) => println(result)
  Err(error) => println("Error: " + error)
}
```

### With Fallback (Enhanced API)
```moonbit
let result = fstring_v2("Hello {0}!", ["World"])
// Always returns a string, fallback on error
```

### Debugging
```moonbit
let analysis = analyze_format_string("{0:10d}")
// Returns detailed information about tokenization and parsing
```

## Error Handling

### Validation Errors
- **Argument Count Mismatch**: Not enough arguments for placeholders
- **Type Compatibility**: Format type doesn't match argument type
- **Parse Errors**: Malformed format strings

### Error Recovery
- **Fallback Strategy**: Enhanced functions fall back to original implementation
- **Graceful Degradation**: Errors don't crash the application
- **Detailed Messages**: Clear error messages with suggestions

## Migration Guide

### From Original API
The original API continues to work unchanged:
```moonbit
// This continues to work
let result = fstring("Hello {0}!", ["World"])
```

### To Enhanced API
For new code, prefer the enhanced API:
```moonbit
// Safe version with explicit error handling
match fstring_safe("Hello {0}!", ["World"]) {
  Ok(result) => result
  Err(error) => "Error: " + error
}

// Or use the fallback version
let result = fstring_v2("Hello {0}!", ["World"])
```

## Future Enhancements

### Planned Features
1. **Async Formatting**: Support for asynchronous value formatting
2. **Custom Formatters**: User-defined format types
3. **Performance Caching**: Caching of parsed format strings
4. **Internationalization**: Support for locale-specific formatting

### Extension Points
The modular architecture supports:
- Custom parser combinators
- Additional validation rules 
- New format specification types
- Pluggable error handling strategies

## Testing

The refactored library maintains all existing tests while adding new ones for enhanced functionality:

- **Original Tests**: All original functionality tests pass
- **Enhanced Tests**: Tests for new error handling and validation
- **Integration Tests**: Tests for interaction between modules
- **Performance Tests**: Benchmarks for optimization validation

## Backward Compatibility

The refactoring maintains 100% backward compatibility:
- All original function signatures unchanged
- All original behavior preserved
- All original tests pass
- No breaking changes to existing code