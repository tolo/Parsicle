//
//  String+Parsicle.swift
//  Part of Parsicle - http://www.github.com/tolo/Parsicle
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/Parsicle/LICENSE)
//

import Foundation

extension StringProtocol where Self.Index == String.Index {
 
  func trim() -> String {
    return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
  
  func index(_ offsetBy: Int) -> Self.Index {
    return index(startIndex, offsetBy: offsetBy)
  }
  
  func index(ofChar char: Character, from intIndex: Int) -> Int {
    guard let stringIndex = self[range(from: intIndex)].firstIndex(of: char) else { return NSNotFound }
    return index(ofIndex: stringIndex)
  }
  
  func index(ofCharInSet charset: CharacterSet, from intIndex: Int) -> Int {
    guard let stringIndex = self[range(from: intIndex)].rangeOfCharacter(from: charset)?.lowerBound else { return NSNotFound }
    return index(ofIndex: stringIndex)
  }
  
  func index(ofIndex index: String.Index) -> Int {
    return distance(from: startIndex, to: index)
  }
  
  func charAt(index charIndex: Int, matches set: CharacterSet) -> Bool {
    let i = index(charIndex)
    return rangeOfCharacter(from: set, options: [], range: i..<index(after: i))?.lowerBound == i
  }
  
  func charAt(index charIndex: Int) -> Character {
    return self[index(startIndex, offsetBy: charIndex)]
  }
  
  func rangeOf(_ string: String, options: String.CompareOptions = [], from index: Int = 0) -> Range<Self.Index>? {
    return range(of: string, options: options, range: range(from: index))
  }
  
  func range(from index: Int) -> Range<Self.Index> {
    return self.index(startIndex, offsetBy: index) ..< endIndex
  }
  
  func range(from: Int, to: Int) -> Range<Self.Index> {
    guard to <= count else { return startIndex ..< endIndex }
    return index(startIndex, offsetBy: from) ..< index(startIndex, offsetBy: to)
  }
  
  func range(length: Int) -> Range<Self.Index> {
    let rangeEnd = index(startIndex, offsetBy: length)
    guard rangeEnd < endIndex else { return startIndex ..< endIndex }
    return startIndex ..< rangeEnd
  }
  
  func substring(from: Int, to: Int) -> Self.SubSequence {
    return self[range(from: from, to: to)]
  }
  
  func substring(from: Int) -> Self.SubSequence {
    return self[range(from: from)]
  }
  
  func replaceCharacterAt(index: Int, length: Int = 1, with string: Self) -> String {
    return replaceCharacterInRange(from: index, to: index + length, with: string)
  }

  func replaceCharacterInRange(from: Int, to: Int, with string: Self) -> String {
    let range = index(startIndex, offsetBy: from) ..< index(startIndex, offsetBy: to)
    return replacingCharacters(in: range, with: string)
  }
}

extension CharacterSet {
  func containsUnicodeScalars(of member: Character) -> Bool {
    return member.unicodeScalars.allSatisfy(contains(_:))
  }
}
