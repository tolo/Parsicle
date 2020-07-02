//
//  Parsicle+BasicMatchers.swift
//  Part of Parsicle - http://www.github.com/tolo/Parsicle
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/Parsicle/LICENSE)
//

import Foundation

public extension Parsicle {
  
  typealias ParserMatchCondition = (_ char: Character) -> Bool

  static func char(_ character: Character, skipSpaces: Bool = false) -> StringParsicle {
    return char(skipSpaces: skipSpaces, name: "char") { return character == $0 }
  }
  
  static func charSpaced(_ character: Character) -> StringParsicle {
    return char(character, skipSpaces: true)
  }
  
  static func charSpacedIgnored<Result>(_ character: Character) -> Parsicle<Result> {
    return char(character, skipSpaces: true).ignore()
  }
  
  static func char(in set: CharacterSet, skipSpaces: Bool = false) -> StringParsicle {
    return char(skipSpaces: skipSpaces, name: "charInSet") { return set.containsUnicodeScalars(of: $0) }
  }
  
  static func char(skipSpaces: Bool, name: String, matching matcher: @escaping ParserMatchCondition) -> StringParsicle {
    let charMatchParsicle = Parsicle<String>(name: name) { input, _ in
      guard input.startIndex < input.endIndex else { return ParsicleStatus<String>(input) }
      let char = input[input.startIndex]
      if matcher(char) {
        return ParsicleStatus(input: input, matchEndIndex: input.index(after: input.startIndex), value: String(char))
      }
      return ParsicleStatus(input)
    }
    return skipSpaces ? charMatchParsicle.skipSurrounding(self.spaces()) : charMatchParsicle
  }
  
  static func string(_ matcherString: String, ignoreCase: Bool = true, skipSpaces: Bool = false) -> StringParsicle {
    let matcherLength: Int = matcherString.count
    
    let stringMatchParsicle = Parsicle<String>(name: "string(\(matcherString))") { input, _ in
      let match = input.commonPrefix(with: matcherString, options: .caseInsensitive)
      if match.count == matcherLength {
        return ParsicleStatus(input: input, matchEndIndex: input.index(matcherLength), value: match)
      } else {
        return ParsicleStatus(input)
      }
    }
    return skipSpaces ? stringMatchParsicle.skipSurrounding(self.spaces()) : stringMatchParsicle
  }
  
  static func space() -> StringParsicle {
    return char(in: CharacterSet.whitespacesAndNewlines)
  }
  
  static func spaces(_ minCount: Int = 0) -> StringParsicle {
    return take(whileIn: CharacterSet.whitespacesAndNewlines, minCount: minCount)
  }
  
  static func digit() -> StringParsicle {
    return char(in: CharacterSet.decimalDigits)
  }
  
  static func digits(_ minCount: Int = 0) -> StringParsicle {
    return take(whileIn: CharacterSet.decimalDigits, minCount: minCount)
  }
}

public extension Parsicle {
  func skipSurroundingSpaces() -> Parsicle<ParserResult> {
    return skipSurrounding(Parsicles.spaces())
  }
}
