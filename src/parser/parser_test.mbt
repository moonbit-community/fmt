///|
test "tag" {
  let parser = tag("hello")
  let input = "hello world"
  match parser(input) {
    Ok(result) => {
      inspect(result, content=" world")
    }
    Err(error) => {
      raise(error)
    }
  }
}

///|
test "panic tag" {
  let parser = tag("hi")
  let input = "hello world"
  match parser(input) {
    Ok(_) => {
      ()
    }
    Err(error) => {
      raise(error)
    }
  }
}
