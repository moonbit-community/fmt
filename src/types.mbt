///|
pub(open) trait Formatter: Show {
  format(Self, FormatSpec) -> String = _
  display(Self, FormatSpec, &Logger) -> Unit = _
}

///|
impl Formatter with display(self, spec : FormatSpec, logger : &Logger) -> Unit {
  logger.write_string(self.format(spec))
}

///|
impl Formatter with format(self, spec : FormatSpec) -> String {
  let sb = StringBuilder::new()
  align_string(spec, self.to_string(), sb)
  sb.to_string()
}
