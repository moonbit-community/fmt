///|
pub(open) trait Formatter {
  format(Self, FormatSpec) -> String = _
  format_stream(Self, FormatSpec, StringBuilder) -> Unit
  display(Self, FormatSpec, &Logger) -> Unit = _
}

///|
impl Formatter with display(self, spec : FormatSpec, logger : &Logger) -> Unit {
  logger.write_string(self.format(spec))
}

///|
impl Formatter with format(self, spec : FormatSpec) -> String {
  let sb = StringBuilder::new()
  self.format_stream(spec, sb)
  sb.to_string()
}
