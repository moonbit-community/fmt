
// Fork from https://github.com/moonbit-community/simple_parserc

///|
pub struct Input {
  chars : @string.View
  offset : Int
}

///|
pub fn Input::new(view : @string.View) -> Input {
  return { chars: view, offset: 0 }
}



pub type Parser[A] (Input) -> (A, Input)!ParseErrorX

///|
pub type! ParseErrorX {
  Expect(offset~ : Int, message~ : String)
  Many(Array[ParseError])
} derive(Show)

pub fn Input::satisfy(f: (Char) -> Bool) -> Parser[Char] {
  fn (input) {
    let { chars, offset } = input
    match chars {
      [x, .. chars] if f(x) =>
        if x == '\n' {
          (x, Input::{ chars, offset: offset + 1 })
        } else {
          (x, Input::{ chars, offset: offset + 1 })
        }
      _ => raise Expect(offset~, message="Expected character satisfying the predicate")
    }
  }
}


test "" {
  // let x = "fwfawfgawgag"
  // let y = "z"
  let w = "pq"

  let v = w[:]
  match w {
    [x, y, z, ..] => {
      fprintln("Matched1: {}, {}, {}", [x, y, z])
      ()
    } 
    [x, y, ..] => {
      fprintln("Matched2: {}, {}", [x, y])
      ()
    }
    [x, ..] => {
      fprintln("Matched3: {}", [x])
      ()
    }
  }
}