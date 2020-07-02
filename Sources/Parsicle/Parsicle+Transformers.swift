//
//  Parsicle+Transformers.swift
//  Part of Parsicle - http://www.github.com/tolo/Parsicle
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/Parsicle/LICENSE)
//

import Foundation

// MARK: - Transformers

public extension Parsicle {

  typealias TransformerBlock<Result, Transformed> = (_ value: Result) -> Transformed?
  
  func map<Transformed>(name: String? = nil, _ transformation: @escaping TransformerBlock<ParserResult, Transformed>) -> Parsicle<Transformed> {
    return Parsicle<Transformed>(name: name ?? String(describing: self)) { input, context in
      let r = self.parse(input, context: context)
      if let value = r.value, r.match {
        let transformed = transformation(value)
        return r.using(updatedValue: transformed)
      } else {
        return r.using(updatedValue: nil)
      }
    }
  }
  
  typealias ContextualizedTransformerBlock<Result, Transformed> = (_ value: Result, _ context: ParsicleContext) -> Transformed?
  
  func map<Transformed>(name: String? = nil, _ transformation: @escaping ContextualizedTransformerBlock<ParserResult, Transformed>) -> Parsicle<Transformed> {
    return Parsicle<Transformed>(name: name ?? String(describing: self)) { input, context in
      let r = self.parse(input, context: context)
      guard let value = r.value, r.match else { return ParsicleStatus(input) }
      let transformed = transformation(value, context)
      return r.using(updatedValue: transformed)
    }
  }
  
  func compact<E>() -> Parsicle<[E]> where ParserResult == [E?] {
    return self.map(name: "compactMap") { $0.compactMap { return $0 } }
  }
  
  func flat<E>() -> Parsicle<[E]> where ParserResult == [[E]] {
    return self.map(name: "compactMap") { $0.flatMap { return $0 } }
  }
  
  /// Ignores the result of this parser, and also transforms the type to the specified type
  func ignore<Result>() -> Parsicle<Result> {
    return Parsicle<Result>(name: "ignore") { input, context in
      let result = self.parse(input, context: context.onlyMatching())
      return result.using(updatedValue: nil)
    }
  }
  
  func cast<Result>() -> Parsicle<Result> {
    return self.map(name: "cast") { $0 as? Result }
  }
  
  func asAny() -> AnyParsicle {
    return Parsicle<Any>(name: "asAny") { input, context in
      let result = self.parse(input, context: context)
      return result.using(updatedValue: result.value)
    }
  }
  
  func optional(defaultValue: ParserResult? = nil) -> Parsicle<ParserResult> {
    return Parsicles.optional(self, defaultValue: defaultValue)
  }
  
  func debug(_ message: String? = nil) -> Parsicle<ParserResult> {
    return Parsicle<ParserResult>(name: "debug(\(description))") { [description] input, context in
      let r = self.parse(input, context: context)
      let msg = message != nil ? "(\(message!))" : ""
      debugPrint("DEBUG \(msg) - parse result for (\(description)): \(r)")
      return r
    }
  }
  
  func rewind() -> Parsicle<ParserResult> {
    return Parsicle<ParserResult>(name: "rewind") { input, context in
      let r = self.parse(input, context: context)
      return ParsicleStatus(input: input, matchEndIndex: input.startIndex, value: r.value)
    }
  }
}

public extension Parsicle {
  static func asNumber(_ value: Value) -> NSNumber? {
    if let value = value as? NSNumber { return value }
    else if let value = value as? NSString { return NSNumber(value: value.doubleValue) }
    else { return nil }
  }
  
  func asNumber() -> Parsicle<NSNumber> {
    return self.map(name: "cast") { Self.asNumber($0) }
  }
  
  func asDouble() -> Parsicle<Double> {
    return self.map(name: "cast") { Self.asNumber($0)?.doubleValue }
  }
  
  func asFloat() -> Parsicle<Float> {
    return self.map(name: "cast") { Self.asNumber($0)?.floatValue }
  }
  
  func asInt() -> Parsicle<Int> {
    return self.map(name: "cast") { Self.asNumber($0)?.intValue }
  }
}
