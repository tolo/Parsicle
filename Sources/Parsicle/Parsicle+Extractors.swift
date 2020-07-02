//
//  Parsicle+Extractors.swift
//  Part of Parsicle - http://www.github.com/tolo/Parsicle
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/Parsicle/LICENSE)
//

import Foundation

public extension Parsicle {
  
  // MARK: - Extractors
  
  static func stringWithEscapesUp(to upToChar: Character, orEndOfInput matchUpToEndOfInput: Bool = true, skipPastEndChar: Bool = false, replaceEscapes: Bool = true, invalidChars: CharacterSet? = nil) -> StringParsicle {
    return stringWithEscapesUp(to: { return upToChar == $0 }, orEndOfInput: matchUpToEndOfInput, skipPastEndChar: skipPastEndChar, replaceEscapes: replaceEscapes, invalidChars: invalidChars, name:  "stringWithEscapesUpToChar(\(upToChar))")
  }
  
  static func stringWithEscapesUp(to upToCharSet: CharacterSet, orEndOfInput matchUpToEndOfInput: Bool = true, skipPastEndChar: Bool = false, replaceEscapes: Bool = true, invalidChars: CharacterSet? = nil) -> StringParsicle {
    return stringWithEscapesUp(to: { return upToCharSet.containsUnicodeScalars(of: $0) }, orEndOfInput: matchUpToEndOfInput, skipPastEndChar: skipPastEndChar, replaceEscapes: replaceEscapes, invalidChars: invalidChars, name: "stringWithEscapesUpToCharInSet")
  }
  
  private static func stringWithEscapesUp(to upToChar: @escaping ParserMatchCondition, orEndOfInput matchUpToEndOfInput: Bool = true, skipPastEndChar: Bool = false, replaceEscapes: Bool = true, invalidChars: CharacterSet? = nil, name: String = "stringWithEscapesUpToChar") -> StringParsicle {
    return Parsicle<String>(name: name) { input, _ in
      guard input.startIndex < input.endIndex else { return ParsicleStatus<String>(input) }
      var index = input.startIndex
      var isBackslash = false, inSingleQuote = false, inDoubleQuote = false
      let inQuote: () -> Bool = { inSingleQuote || inDoubleQuote }
      var match = false
      var invalidCharsFound = false

      while index < input.endIndex {
        let charAtIndex = input[index]
        let notEscapeOrQuoute = !isBackslash && !inQuote()
        if notEscapeOrQuoute && (invalidChars?.containsUnicodeScalars(of: charAtIndex) ?? false) {
          invalidCharsFound = true
          break
        }
        if notEscapeOrQuoute && upToChar(charAtIndex) {
          match = true
          break
        } else if charAtIndex == "\'" && !inDoubleQuote && !isBackslash {
          inSingleQuote = !inSingleQuote
        } else if charAtIndex == "\"" && !inSingleQuote && !isBackslash {
          inDoubleQuote = !inDoubleQuote
        } else if charAtIndex == "\\" {
          isBackslash = !isBackslash // Set if backslash found, reset for double backslash
        } else {
          isBackslash = false
        }
        index = input.index(after: index)
      }
      if invalidCharsFound || (!match && !matchUpToEndOfInput) {
        return ParsicleStatus(input) // Fail if 'upToChar' not found and 'matchUpToEndOfInput' is false
      }

      // Replace escapes
      var string = String(input[..<index])
      if replaceEscapes {
        var c = 0
        while c < string.count {
          let charAtIndex = string.charAt(index: c)
          if charAtIndex == "\\" {
            if isBackslash { // Double backslash
              string = string.replaceCharacterAt(index: c, with: "")
              c -= 1
              isBackslash = false
            } else { // Backslash found
              isBackslash = true
            }
          } else if isBackslash { // Previous character is backslash
            isBackslash = false
            if charAtIndex == "n" {
              string = string.replaceCharacterAt(index: c-1, length: 2, with: "\n")
            } else if charAtIndex == "t" {
              string = string.replaceCharacterAt(index: c-1, length: 2, with: "\t")
            } else if charAtIndex == "\'" || charAtIndex == "\"" {
              string = string.replaceCharacterAt(index: c-1, length: 1, with: "")
            } else {
              c += 1
            }
            c -= 1
          }
          c += 1
        }
      }

      if index < input.endIndex {
        index = skipPastEndChar ? input.index(after: index) : index
      }
      return ParsicleStatus(input: input, matchEndIndex: index, value: string)
    }
  }
  
  static func paramList(startChar: Character = "(", separatorChar: Character = ",", endChar: Character = ")", invalidChars: CharacterSet? = nil) -> Parsicle<[String]> {
    return Parsicle<[String]>(name: "nestableParamListString") { input, _ in
      guard input.startIndex < input.endIndex else { return ParsicleStatus(input) }
      var index = input.startIndex
      guard input[index] == startChar else { return ParsicleStatus(input) }
      index = input.index(after: index)
      
      var isBackslash = false, inSingleQuote = false, inDoubleQuote = false
      let inQuote: () -> Bool = { inSingleQuote || inDoubleQuote }
      var match = false
      var paramListLevel = 0
      var parameterBeginIndex = index
      var parameters: [String] = []
      
      while (index < input.endIndex) && !match {
        let charAtIndex = input[index]
        let notEscapeOrQuoute = !isBackslash && !inQuote()
        
        if notEscapeOrQuoute && (invalidChars?.containsUnicodeScalars(of: charAtIndex) ?? false) {
          break
        }
        else if notEscapeOrQuoute && charAtIndex == startChar {
          paramListLevel += 1
        }
        else if notEscapeOrQuoute && paramListLevel == 0 && charAtIndex == separatorChar {
          parameters.append(String(input[parameterBeginIndex..<index]).trim())
          parameterBeginIndex = input.index(after: index)
        }
        else if notEscapeOrQuoute && paramListLevel == 0 && charAtIndex == endChar {
          parameters.append(String(input[parameterBeginIndex..<index]).trim())
          match = true
        }
        else if notEscapeOrQuoute && charAtIndex == endChar {
          paramListLevel -= 1
        }
        else if charAtIndex == "\\" {
          isBackslash = !isBackslash // Set if backslash found, reset for double backslash
        }
        else if charAtIndex == "\'" && !inDoubleQuote && !isBackslash {
          inSingleQuote = !inSingleQuote
        }
        else if charAtIndex == "\"" && !inSingleQuote && !isBackslash {
          inDoubleQuote = !inDoubleQuote
        }
        
        isBackslash = false
        index = input.index(after: index)
      }
      
      if match {
        return ParsicleStatus(input: input, matchEndIndex: index, value: parameters)
      } else {
        return ParsicleStatus(input)
      }
    }
  }
  
  static func take(untilIn characterSet: CharacterSet, minCount: Int = 0) -> StringParsicle {
    return takeWhileCharMatches(minCount: minCount, skipPastEndChar: false, name: "takeUntilInSet") {
      return !characterSet.containsUnicodeScalars(of: $0)
    }
  }
  
  static func take(untilChar character: Character, andSkip skip: Bool = false, minCount: Int = 0) -> StringParsicle {
    return self.takeWhileCharMatches(minCount: minCount, skipPastEndChar: skip, name: "takeUntilChar") { $0 != character }
  }
  
  static func take(untilString string: String, andSkip skip: Bool = false) -> StringParsicle {
    let matchLength = string.count
    
    return Parsicle<String>(name: "takeUntilString") { input, status in
      var index = input.startIndex
      var buffer = String()

      while index < input.endIndex {
        buffer.append(input[index])
        buffer = String(buffer.suffix(matchLength))
        index = input.index(after: index)
        if buffer == string {
          let valueEndIndex = input.index(index, offsetBy: -matchLength)
          let matchEndIndex = skip ? index : valueEndIndex
          return ParsicleStatus(input: input, matchEndIndex: matchEndIndex, value: String(input[..<valueEndIndex]))
        }
      }
      return ParsicleStatus(input: input, matchEndIndex: index, value: String(input))
    }
  }
  
  static func take(whileIn characterSet: CharacterSet, minCount: Int = 0) -> StringParsicle {
    return take(whileIn: characterSet, withInitialCharSet: nil, minCount: minCount)
  }
  
  static func take(whileIn characterSet: CharacterSet, withInitialCharSet initialCharSet: CharacterSet?, minCount: Int = 0) -> StringParsicle {
    let characterSetMatcher: ParserMatchCondition = { characterSet.containsUnicodeScalars(of: $0) }
    if let initialCharSet = initialCharSet {
      return takeWhileCharMatches(minCount: minCount, skipPastEndChar: false, name: "takeWhileInSet", initialCharMatcher: {
        initialCharSet.containsUnicodeScalars(of: $0)
      }, matcher: characterSetMatcher)
    } else {
      return takeWhileCharMatches(minCount: minCount, skipPastEndChar: false, name: "takeWhileInSet", matcher: characterSetMatcher)
    }
  }
  
  private static func takeWhileCharMatches(minCount: Int = 0, skipPastEndChar: Bool = false, name: String,
                                           initialCharMatcher: ParserMatchCondition? = nil, matcher: @escaping ParserMatchCondition) -> StringParsicle {
    return Parsicle<String>(name: name) { input, _ in
      var index = input.startIndex
      var c = 0
      if let initialCharMatcher = initialCharMatcher, index < input.endIndex {
        if let first = input.first, initialCharMatcher(first) {
          index = input.index(after: index)
          c += 1
        }
        else { return ParsicleStatus(input) }
      }
      
      while index < input.endIndex {
        if !matcher(input[index]) { break }
        index = input.index(after: index)
        c += 1
      }
      
      if c >= minCount {
        let matchEndIndex = skipPastEndChar ? input.index(after: index) : index
        return ParsicleStatus(input: input, matchEndIndex: matchEndIndex, value: String(input[..<index]))
      }
      else { return ParsicleStatus(input) }
    }
  }
}
