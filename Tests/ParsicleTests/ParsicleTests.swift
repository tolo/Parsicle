import XCTest
@testable import Parsicle

typealias S = StringParsicle

final class ParsicleTests: XCTestCase {
  
  func testChar() {
    var yParser = Parsicles.char("y")
    XCTAssertTrue(yParser.matches("y"))
    XCTAssertFalse(yParser.matches("x"))
    let result = yParser.parse("yo!")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.residual, "o!")
    yParser = Parsicles.charSpaced("y")
    XCTAssertTrue(yParser.matches(" y "))
    XCTAssertTrue(yParser.matches("  y  "))
    XCTAssertTrue(yParser.matches(" y"))
    XCTAssertTrue(yParser.matches("y "))
    XCTAssertFalse(yParser.matches(" "))
  }
  
  func testString() {
    let yoParser = Parsicles.string("yo!😃")
    XCTAssertTrue(yoParser.matches("yo!😃"))
    XCTAssertTrue(yoParser.matches("YO!😃"))
    XCTAssertFalse(yoParser.matches("yo!"))
    let result = yoParser.parse("yo!😃😃")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.residual, "😃")
  }
  
  func testDigits() {
    var digitParser = Parsicles.digit()
    XCTAssertTrue(digitParser.matches("1"))
    XCTAssertFalse(digitParser.matches("A"))
    digitParser = Parsicles.digits()
    XCTAssertTrue(digitParser.matches("123"))
    let result = digitParser.parse("123😃")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.residual, "😃")
  }
  
  func testChoice() {
    let yoParser = Parsicles.string("yo!😃")
    let noParser = Parsicles.string("no!😃")
    let parser = Parsicles.choice([yoParser, noParser])
    XCTAssertTrue(parser.matches("yo!😃"))
    XCTAssertTrue(parser.matches("no!😃"))
    XCTAssertFalse(yoParser.matches("yo!"))
    XCTAssertFalse(yoParser.matches("no!"))
    let result = parser.parse("yo!😃😃")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.residual, "😃")
  }
  
  func testOptional() {
    let parser = Parsicles.sequential([S.char("😃").optional(), .char("y"), .char("o"), S.char("😃").optional()])
    XCTAssertTrue(parser.matches("yo"))
    XCTAssertTrue(parser.matches("yo😃"))
    XCTAssertTrue(parser.matches("😃yo"))
    XCTAssertTrue(parser.matches("😃yo😃"))
    XCTAssertFalse(parser.matches("!yo"))
    XCTAssertFalse(parser.matches("yo!"))
    XCTAssertFalse(parser.matches("😃y"))
    XCTAssertFalse(parser.matches("o😃"))
    let parser2 = Parsicles.char("A").optional(defaultValue: "?").then(.char("B"))
    var result = parser2.parse("AB")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["A", "B"])
    XCTAssertEqual(result.residual, "")
    result = parser2.parse("BC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["?", "B"])
    XCTAssertEqual(result.residual, "C")
  }
  
  func testSequential() {
    let yoParser = Parsicles.sequential([.char("y"), .char("o"), .char("!"), .char("😃")])
    XCTAssertTrue(yoParser.matches("yo!😃"))
    XCTAssertFalse(yoParser.matches("yo!"))
    let result = yoParser.parse("yo!😃😃")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.residual, "😃")
  }
  
  func testEndOfInput() {
    let yoParser = Parsicles.sequential([.char("y"), .char("o"), S.endOfInput()])
    XCTAssertTrue(yoParser.parse("yo").match)
    XCTAssertFalse(yoParser.parse("yo!").match)
    XCTAssertFalse(yoParser.parse("y").match)
  }
  
  func testOr() {
    let parser = Parsicles.string("AB").or(.string("BA"))
    XCTAssertTrue(parser.matches("AB"))
    XCTAssertTrue(parser.matches("BA"))
    XCTAssertFalse(parser.matches("A"))
    XCTAssertFalse(parser.matches("B"))
  }
  
  func testThen() {
    let yoParser = Parsicles.char("y").then(.char("o"))
    XCTAssertTrue(yoParser.matches("yo"))
    XCTAssertFalse(yoParser.matches("y"))
    XCTAssertFalse(yoParser.matches("oy"))
    let intParser = Parsicles.digit().map { Int($0) }
    let intAParser = intParser.then(.char("A"))
    let intAIntParser = intAParser.then(intParser)
    let r1 = intAIntParser.parse("1A0")
    XCTAssertTrue(r1.match)
    XCTAssertEqual(r1.value?.0, 1)
    XCTAssertEqual(r1.value?.1, "A")
    XCTAssertEqual(r1.value?.2, 0)
    XCTAssertEqual(r1.residual, "")
    let intAIntBParser = intAIntParser.then(.char("B"))
    let r2 = intAIntBParser.parse("1A0B")
    XCTAssertTrue(r2.match)
    XCTAssertEqual(r2.value?.0, 1)
    XCTAssertEqual(r2.value?.1, "A")
    XCTAssertEqual(r2.value?.2, 0)
    XCTAssertEqual(r2.value?.3, "B")
    XCTAssertEqual(r2.residual, "")
  }
  
  func testKeepLeft() {
    let parser = Parsicles.char("A").keepLeft(.char("B"))
    var result = parser.parse("AB")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "A")
    XCTAssertEqual(result.residual, "")
    result = parser.parse("BA")
    XCTAssertFalse(result.match)
    XCTAssertEqual(result.residual, "BA")
    result = parser.parse("A")
    XCTAssertFalse(result.match)
  }
  
  func testKeepRight() {
    let parser = Parsicles.char("A").keepRight(.char("B"))
    var result = parser.parse("AB")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "B")
    XCTAssertEqual(result.residual, "")
    result = parser.parse("BA")
    XCTAssertFalse(result.match)
    XCTAssertEqual(result.residual, "BA")
    result = parser.parse("B")
    XCTAssertFalse(result.match)
  }
  
  func testBetween() {
    let parser = Parsicles.char("B").between(.char("A"), and: .char("C"))
    var result = parser.parse("ABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "B")
    XCTAssertEqual(result.residual, "")
    result = parser.parse("CBA")
    XCTAssertFalse(result.match)
    XCTAssertEqual(result.residual, "CBA")
    result = parser.parse("B")
    XCTAssertFalse(result.match)
  }
  
  func testLazyBetween() {
    var parser = Parsicles.char("B").lazyBetween(.char("A"), and: .char("C"))
    var result = parser.parse("ABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "B")
    XCTAssertEqual(result.residual, "")
    parser = Parsicles.digits().lazyBetween(.char("0"), and: .char("0"))
    result = parser.parse("01230")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "123")
    XCTAssertEqual(result.residual, "")
    result = parser.parse("012300")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "1230")
    XCTAssertEqual(result.residual, "")
    result = parser.parse("0123001")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "1230")
    XCTAssertEqual(result.residual, "1")
  }
  
  func testMany() {
    let parser = Parsicles.char("A").many()
    XCTAssertTrue(parser.matches("A"))
    var result = parser.parse("AA")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["A", "A"])
    XCTAssertEqual(result.residual, "")
    result = parser.parse("AAAB")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["A", "A", "A"])
    XCTAssertEqual(result.residual, "B")
  }
  
  func testManyMinCout() {
    var parser = Parsicles.char("A").many(1)
    XCTAssertFalse(parser.matches(""))
    XCTAssertTrue(parser.matches("A"))
    XCTAssertTrue(parser.matches("AA"))
    parser = Parsicles.char("A").many(2)
    XCTAssertFalse(parser.matches("A"))
    XCTAssertTrue(parser.matches("AA"))
    XCTAssertTrue(parser.matches("AAA"))
  }
  
  func testConcatMany() {
    let parser = Parsicles.char("A").concatMany()
    var result = parser.parse("A")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "A")
    XCTAssertEqual(result.residual, "")
    result = parser.parse("AAA")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "AAA")
    XCTAssertEqual(result.residual, "")
    result = parser.parse("AAAB")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "AAA")
    XCTAssertEqual(result.residual, "B")
  }
  
  func testSepBy() {
    let numberParser = Parsicles.char(in: .decimalDigits).map { Int($0) }
    let parser = numberParser.sepBy(.char(","))
    XCTAssertTrue(parser.matches("1"))
    XCTAssertTrue(parser.matches("1,1"))
    let result = parser.parse("1,1,1,")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, [1, 1, 1])
    XCTAssertEqual(result.residual, ",")
  }

  func testSepByKeep() {
    let parser = Parsicles.char("A").sepByKeep(.char(","))
    XCTAssertTrue(parser.matches("A"))
    let result = parser.parse("A,A,A,")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["A", ",", "A", ",", "A"])
    XCTAssertEqual(result.residual, ",")
  }
  
  func testSkipSurrounding() {
    let parser = Parsicles.char("A").skipSurrounding(.char("B"))
    let result = parser.parse("A")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "A")
    XCTAssertEqual(result.residual, "")
    XCTAssertTrue(parser.matches("A"))
    XCTAssertTrue(parser.matches("BAB"))
  }
  
  func testCompact() {
    let aParser: Parsicle<String?> = Parsicles.char("A").map { $0 }
    let bParser: Parsicle<String?> = Parsicles.char("B").map { _ in nil }
    let parser = aParser.or(bParser).manyO()
    XCTAssertTrue(parser.matches("ABAB"))
    let result = parser.parse("ABAB")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["A", nil, "A", nil])
    XCTAssertEqual(result.residual, "")
  }
  
  func testFlattened() {
    let aParser = Parsicles.char("A").map { [$0] }
    let parser = aParser.many().flat()
    XCTAssertTrue(parser.matches("AA"))
    let result = parser.parse("AA")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["A", "A"])
    XCTAssertEqual(result.residual, "")
  }
    
  func testStringWithEscapesUp() {
    let parser = Parsicles.stringWithEscapesUp(to: "😃")
    var result = parser.parse("\"Hello\"😃")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "\"Hello\"")
    XCTAssertEqual(result.residual, "😃")
    result = parser.parse("\"Hello\" \"😃\"") // Matches until end of line
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "\"Hello\" \"😃\"")
    XCTAssertEqual(result.residual, "")
  }
  
  func testTakeUntilInSet() {
    let parser = Parsicles.take(untilIn: .whitespacesAndNewlines)
    XCTAssertTrue(parser.matches("ABC"))
    let result = parser.parse("ABC ABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "ABC")
    XCTAssertEqual(result.residual, " ABC")
  }
  
  func testTakeUntilChar() {
    var parser = Parsicles.take(untilChar: "X")
    XCTAssertTrue(parser.matches("ABC"))
    var result = parser.parse("ABCXABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "ABC")
    XCTAssertEqual(result.residual, "XABC")
    parser = Parsicles.take(untilChar: "X", andSkip: true)
    result = parser.parse("ABCXABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "ABC")
    XCTAssertEqual(result.residual, "ABC")
  }
  
  func testTakeUntilString() {
    var parser = Parsicles.take(untilString: " MUPP ")
    XCTAssertTrue(parser.matches("ABC"))
    var result = parser.parse("ABC MUPP ABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "ABC")
    XCTAssertEqual(result.residual, " MUPP ABC")
    parser = Parsicles.take(untilString: " MUPP ", andSkip: true)
    result = parser.parse("ABC MUPP ABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "ABC")
    XCTAssertEqual(result.residual, "ABC")
  }
  
  func testTakeWhileInSet() {
    var parser = Parsicles.take(whileIn: .alphanumerics)
    XCTAssertTrue(parser.matches("ABC"))
    var result = parser.parse("ABC ABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "ABC")
    XCTAssertEqual(result.residual, " ABC")
    parser = Parsicles.take(whileIn: .alphanumerics, withInitialCharSet: .decimalDigits)
    XCTAssertTrue(parser.matches("1ABC"))
    XCTAssertFalse(parser.matches("ABC"))
    result = parser.parse("1ABC 1ABC")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "1ABC")
    XCTAssertEqual(result.residual, " 1ABC")
  }
  
  func testBeforeEOI() {
    let p = StringParsicle.char("A").beforeEOI()
    let result = p.parse("A")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, "A")
    XCTAssertEqual(result.residual, "")
  }
  
  func testParamList() {
    let p = Parsicles.paramList()
    var result = p.parse("(A, B,C)")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["A", "B", "C"])
    XCTAssertEqual(result.residual, "")
    result = p.parse("(A ,B,(C,func(D,E)))")
    XCTAssertTrue(result.match)
    XCTAssertEqual(result.value, ["A", "B", "(C,func(D,E))"])
    XCTAssertEqual(result.residual, "")
  }
    
  func testBuilder1() {
    let parser = Sequential {
      "Hello"
      Spaces(1)
      "World"
      Spaces().optional()
      Choice {
        "🤯"
        "😍"
        "💩"
      }
    }
    
    XCTAssertTrue(parser.matches("Hello World 🤯"))
    XCTAssertTrue(parser.matches("Hello World😍"))
    XCTAssertTrue(parser.matches("Hello World 💩"))
    XCTAssertFalse(parser.matches("HelloWorld💩"))
    XCTAssertFalse(parser.matches("Hello World 🤬"))
  }
  
  func testBuilder2() {
    let parser: Parsicle<[String]> = Sequential {
      String("Hello").ignore()
      Spaces(1).ignore()
      "World"
      Spaces().optional().ignore()
      Choice {
        "🤯"
        "😍"
        "💩"
      }
    }.cast()
    
    let parseResult = parser.parse("Hello World 🤯")
    let result = parseResult.value?.joined()
    XCTAssertEqual(result, "World🤯")
  }
  
  func testComment() {
    var commentParser = S.string("/*").keepRight(S.take(untilString: "*/", andSkip: true))
    commentParser = commentParser.map { $0.trim() }
    let many = commentParser.skipSurroundingSpaces().many()
    
    let result1 = commentParser.parse("/* MU */")
    XCTAssertTrue(result1.match)
    XCTAssertEqual(result1.value, "MU")
    XCTAssertEqual(result1.residual, "")
    
    let result2 = many.parse("/* MU */\n\n/* MUPP */")
    XCTAssertTrue(result2.match)
    XCTAssertEqual(result2.value, ["MU", "MUPP"])
    XCTAssertEqual(result2.residual, "")
  }
}
