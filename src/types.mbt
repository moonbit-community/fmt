///|
pub(open) trait Formatter: Show {
  display(Self, FormatSpec, StringBuilder) -> Unit = _
}

///|
impl Formatter with display(self, spec : FormatSpec, sb : StringBuilder) -> Unit {
  align_string(spec, self.to_string(), sb)
}
