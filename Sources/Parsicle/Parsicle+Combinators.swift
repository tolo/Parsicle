//
//  Parsicle+Combinators.swift
//  Part of Parsicle - http://www.github.com/tolo/Parsicle
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/Parsicle/LICENSE)
//

import Foundation

public extension Parsicle {
  
  // MARK: - Basic combinator builders
  
  static func choice<Result>(_ parsers: [Parsicle<Result>], name: String = "choice") -> Parsicle<Result> {
    return Parsicle<Result>(name: name) { input, context in
      for parser in parsers {
        let result = parser.parse(input, context: context)
        if result.match { return result }
      }
      return ParsicleStatus(input)
    }
  }
  
  static func anyChoice<Result>(_ parsers: [Parsicle<Result>], name: String = "anyChoice") -> AnyParsicle { // TODO: Ambiguous name?
    return choice(parsers, name: name).asAny()
  }

  static func optional<Result>(_ parser: Parsicle<Result>, defaultValue: Result? = nil) -> Parsicle<Result> {
    return Parsicle<Result>(name: "optional(\(String(describing: defaultValue)))") { input, context in
      let result = parser.parse(input, context: context)
      if !result.match {
        return ParsicleStatus(input: input, matchEndIndex: input.startIndex, value: defaultValue)
      }
      return result
    }
  }
  
  static func sequentialO<Result>(_ parsers: [Parsicle<Result>], name: String = "sequentialOptionals") -> Parsicle<[Result?]> {
    return Parsicle<[Result?]>(name: name) { input, context in
      var sequentialResult = [Result?]()
      var parserInput = input
      var finalMatchEndIndex = input.startIndex
      for parser in parsers {
        let r = parser.parse(parserInput, context: context)
        guard r.match, let matchEndIndex = r.matchEndIndex else {
          return ParsicleStatus(input)
        }
        sequentialResult.append(r.value)
        parserInput = r.residual
        finalMatchEndIndex = matchEndIndex
      }
      return ParsicleStatus(input: input, matchEndIndex: finalMatchEndIndex, value: sequentialResult)
    }
  }
  
  static func sequential<Result>(_ parsers: [Parsicle<Result>], name: String = "sequential") -> Parsicle<[Result]> {
    return sequentialO(parsers, name: name).compact()
  }
  
  static func lazyBetween<Result, Prefix, Suffix>(prefix: Parsicle<Prefix>, content: Parsicle<Result>, suffix: Parsicle<Suffix>, name: String = "sequentialOptionals") -> Parsicle<Result> {
    return Parsicle<Result>(name: name) { input, context in
      let onlyMatchingContext = context.onlyMatching()
      let prefixResult = prefix.parse(input, context: onlyMatchingContext)
      var finalMatchEndIndex = input.startIndex
      guard prefixResult.match, let prefixEnd = prefixResult.matchEndIndex else { return ParsicleStatus(input) }
      
      // Parse content, but flag that parsing is only for matching (i.e value transformations etc can be skipped)
      let contentResult = content.parse(prefixResult.residual, context: onlyMatchingContext)
      guard contentResult.match, let greedyMatchEndIndex = contentResult.matchEndIndex else { return ParsicleStatus(input) }
      let suffixResult = suffix.parse(contentResult.residual, context: onlyMatchingContext)
      // Attempt simple sequential match:
      if suffixResult.match, let suffixEnd = suffixResult.matchEndIndex {
        return ParsicleStatus(input: input, matchEndIndex: suffixEnd, value: contentResult.value)
      }
      
      // Otherwise - attempt lazy match of content, up to greedyMatchEndIndex - one char at a time
      var suffixStart = input.index(before: greedyMatchEndIndex)
      var result: Result?
      while suffixStart > prefixEnd {
        let suffixResult = suffix.parse(input[suffixStart..<greedyMatchEndIndex], context: onlyMatchingContext)
        if suffixResult.match, let suffixEnd = suffixResult.matchEndIndex {
          let contentResult = content.parse(input[prefixEnd..<suffixStart], context: context)
          guard contentResult.match else { break }
          finalMatchEndIndex = suffixEnd
          result = contentResult.value
          break
        }
        suffixStart = input.index(before: suffixStart)
      }
      
      if finalMatchEndIndex > input.startIndex {
        return ParsicleStatus(input: input, matchEndIndex: finalMatchEndIndex, value: result)
      } else {
        return ParsicleStatus(input)
      }
    }
  }
  
  
  // MARK: - EOI
  
  static func endOfInput() -> Parsicle<ParserResult> {
    return Parsicle<ParserResult>(name: "endOfInput") { input, _ in
      if input.startIndex == input.endIndex {
        return ParsicleStatus(input: input, matchEndIndex: input.endIndex, value: nil)
      }
      return ParsicleStatus(input)
    }
  }
}

public extension Parsicle {
  
  // MARK: - Basic combinators
  
  func map<OtherResult>(_ mapParser: Parsicle<OtherResult>) -> Parsicle<[OtherResult]> where ParserResult == [String] {
    return Parsicle<[OtherResult]>(name: "map") { input, context in
      let r = self.parse(input, context: context)
      guard let matchEndIndex = r.matchEndIndex, let values = r.value else { return ParsicleStatus(input) }
      let result = values.compactMap{ mapParser.parse($0).value }
      if result.count == values.count {
        return ParsicleStatus(input: input, matchEndIndex: matchEndIndex, value: result)
      }
      return ParsicleStatus(input)
    }
  }
  
  func or(_ orParser: Parsicle) -> Parsicle<ParserResult> {
    return Parsicles.choice([self, orParser])
  }
  
  func or<OtherResult>(_ orParser: Parsicle<OtherResult>) -> Parsicle<Any> {
    return Parsicles.choice([self.asAny(), orParser.asAny()])
  }
  
  func then(_ parser: Parsicle) -> Parsicle<[ParserResult]> {
    return Parsicles.sequential([self, parser], name: "then")
  }
  
  func then<OtherResult, Result>(_ parser: Parsicle<OtherResult>, _ mapper: @escaping (ParserResult, OtherResult) -> Result) -> Parsicle<Result> {
    return Parsicles.sequential([self.asAny(), parser.asAny()], name: "then").map {
      guard let a = $0[0] as? ParserResult, let b = $0[1] as? OtherResult else { return nil }
      return mapper(a, b)
    }
  }
  
  func then<OtherResult>(_ parser: Parsicle<OtherResult>) -> Parsicle<(ParserResult, OtherResult)> {
    return then(parser) { pr, or in return (pr, or) }
  }
  
  func then<OR1, OR2>(_ parser: Parsicle<(OR1, OR2)>) -> Parsicle<(ParserResult, OR1, OR2)> {
    return then(parser) { pr, or in return (pr, or.0, or.1) }
  }
  
  func then<OR1, OR2, OR3>(_ parser: Parsicle<(OR1, OR2, OR3)>) -> Parsicle<(ParserResult, OR1, OR2, OR3)> {
    return then(parser) { pr, or in return (pr, or.0, or.1, or.2) }
  }
  
  func then<OR1, OR2, OR3, OR4>(_ parser: Parsicle<(OR1, OR2, OR3, OR4)>) -> Parsicle<(ParserResult, OR1, OR2, OR3, OR4)> {
    return then(parser) { pr, or in return (pr, or.0, or.1, or.2, or.3) }
  }
  
  func then<PR1, PR2, OR>(_ parser: Parsicle<OR>) -> Parsicle<(PR1, PR2, OR)> where ParserResult == (PR1, PR2) {
    return then(parser) { pr, or in return (pr.0, pr.1, or) }
  }
  
  func then<PR1, PR2, PR3, OR>(_ parser: Parsicle<OR>) -> Parsicle<(PR1, PR2, PR3, OR)> where ParserResult == (PR1, PR2, PR3) {
    return then(parser) { pr, or in return (pr.0, pr.1, pr.2, or) }
  }
  
  func then<PR1, PR2, PR3, PR4, OR>(_ parser: Parsicle<OR>) -> Parsicle<(PR1, PR2, PR3, PR4, OR)> where ParserResult == (PR1, PR2, PR3, PR4) {
    return then(parser) { pr, or in return (pr.0, pr.1, pr.2, pr.3, or) }
  }
  
  func then<PR1, PR2, OR1, OR2>(_ parser: Parsicle<(OR1, OR2)>) -> Parsicle<(PR1, PR2, OR1, OR2)> where ParserResult == (PR1, PR2) {
    return then(parser) { pr, or in return (pr.0, pr.1, or.0, or.1) }
  }
  
  func keepLeft<RightResult>(_ parser: Parsicle<RightResult>) -> Parsicle<ParserResult> {
    return Parsicles.sequential([self, parser.ignore()], name: "keepLeft").map { $0.count > 0 ? $0[0] : nil }
  }
  
  func keepRight<RightResult>(_ parser: Parsicle<RightResult>) -> Parsicle<RightResult> {
    return Parsicles.sequential([self.ignore(), parser], name: "keepRight").map { $0.count > 0 ? $0[0] : nil }
  }
  
  func between<LeftResult, RightResult>(_ left: Parsicle<LeftResult>, and right: Parsicle<RightResult>, name: String = "between") -> Parsicle<ParserResult> {
    return Parsicles.sequential([left.ignore(), self, right.ignore()], name: name).map { $0.count > 0 ? $0[0] : nil }
  }
  
  func lazyBetween<LeftResult, RightResult>(_ left: Parsicle<LeftResult>, and right: Parsicle<RightResult>, name: String = "lazyBetween") -> Parsicle<ParserResult> {
    return Parsicles.lazyBetween(prefix: left, content: self, suffix: right, name: name)
  }
  
  
  // MARK: - Many
  
  func manyO(_ minCount: Int = 1) -> Parsicle<[ParserResult?]> {
    return Parsicle<[ParserResult?]>(name: "many(\(minCount))") { input, context in
      var values = [ParserResult?]()
      var parserInput = input
      var finalMatchEndIndex = input.startIndex
      repeat {
        let result = self.parse(parserInput, context: context)
        if result.match, let matchEndIndex = result.matchEndIndex, matchEndIndex > finalMatchEndIndex {
          parserInput = result.residual
          finalMatchEndIndex = matchEndIndex
          values.append(result.value)
        } else { break }
      } while parserInput.startIndex < parserInput.endIndex
      
      if values.count >= minCount {
        return ParsicleStatus(input: input, matchEndIndex: finalMatchEndIndex, value: values)
      }
      return ParsicleStatus(input)
    }
  }
  
  func many(_ minCount: Int = 1) -> Parsicle<[ParserResult]> {
    return manyO(minCount).compact()
  }
  
  
  // MARK: - Concatenation
  
  func concat<E>(_ separator: String = "", name: String = "concat") -> Parsicle<String> where ParserResult == [E] {
    return map {
      let flattened = $0.compactMap { (e: Any) in e as? String ?? String(describing: e) }
      return flattened.joined(separator: separator)
    }
  }
  
  func concatMany() -> Parsicle<String> {
    return many().concat(name: "concatMany")
  }
  
  
  // MARK: - Separators
  
  func sepBy1<D>(_ delimiterParser: Parsicle<D>) -> Parsicle<[ParserResult]> {
    return sepBy(delimiterParser, minSepCount: 1, name: "sepBy1")
  }
  
  func sepBy<D>(_ delimiterParser: Parsicle<D>, minSepCount: Int = 0, name: String = "sepBy") -> Parsicle<[ParserResult]> {
    return sep(by: delimiterParser.ignore(), minSepCount: minSepCount, keep: false, name: name)
  }
  
  func sepBy1Keep(_ delimiterParser: Parsicle<ParserResult>) -> Parsicle<[ParserResult]> {
    return sepByKeep(delimiterParser, minSepCount: 1, name: "sepBy1Keep")
  }
  
  func sepByKeep(_ delimiterParser: Parsicle<ParserResult>, minSepCount: Int = 0, name: String = "sepByKeep") -> Parsicle<[ParserResult]> {
    return sep(by: delimiterParser, minSepCount: minSepCount, name: name)
  }
  
  private func sep(by delimiterParser: Parsicle<ParserResult>, minSepCount: Int, keep: Bool = true, name: String = "sepBy")
    -> Parsicle<[ParserResult]> {
      let delimeterAndValueParser = delimiterParser.then(self)
      return Parsicle<[ParserResult]>(name: name) { input, context in
        var values: [ParserResult] = []
        let firstResult = self.parse(input, context: context) // Parse first value
        guard let firstValue = firstResult.value, /*firstResult.match,*/ let matchEndIndex = firstResult.matchEndIndex else {
          return ParsicleStatus(input)
        }
        var parserInput = firstResult.residual
        var finalMatchEndIndex = matchEndIndex
        values.append(firstValue)
        var sepCount = 0
        while parserInput.startIndex < parserInput.endIndex {
          let result = delimeterAndValueParser.parse(parserInput, context: context)
          if let parserValues = result.value, !keep || parserValues.count == 2 , /*status.match,*/ let matchEndIndex = result.matchEndIndex {
            if keep { values.append(parserValues.first!) }
            values.append(parserValues.last!)
            parserInput = result.residual
            finalMatchEndIndex = matchEndIndex
          } else { break }
          sepCount += 1
        }
        
        if sepCount >= minSepCount {
          return ParsicleStatus(input: input, matchEndIndex: finalMatchEndIndex, value: values)
        }
        return ParsicleStatus(input)
      }
  }
  
  
  // MARK: - Skipping
  
  func skipSurrounding<T>(_ surroundingContentParser: Parsicle<T>) -> Parsicle<ParserResult> {
    return Parsicles.sequential([surroundingContentParser.ignore().optional(), self, surroundingContentParser.ignore().optional()], name: "skipSurrounding").map { $0[0] }
  }

  
  // MARK: - EOI
  
  func beforeEOI() -> Parsicle<ParserResult> {
    return keepLeft(Parsicle<ParserResult>.endOfInput())
  }
}
