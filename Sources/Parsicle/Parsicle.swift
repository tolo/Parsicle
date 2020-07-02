//
//  Parsicle.swift
//  Part of Parsicle - http://www.github.com/tolo/Parsicle
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/Parsicle/LICENSE)
//

import Foundation

public struct ParsicleStatus<Value>: CustomStringConvertible {  // TODO: Rename?
  public let input: Substring
  public let matchEndIndex: String.Index?
  public let value: Value?

  public var match: Bool { return matchEndIndex != nil }

  public var residual: Substring {
    if let index = matchEndIndex {
      return input[index...]
    } else {
      return input
    }
  }
  
  public var description: String {
    return "match: \(match ? "yes" : "no"), value: \(String(describing: value)), residual count: \(residual.count)"
  }
}

public extension ParsicleStatus {
  init(_ input: Substring) {
    self.init(input: input, matchEndIndex: nil, value: nil)
  }
  
  func using<UpdatedValue>(updatedValue: UpdatedValue?) -> ParsicleStatus<UpdatedValue> {
    return ParsicleStatus<UpdatedValue>(input: input, matchEndIndex: matchEndIndex, value: updatedValue)
  }
  
  func using(matchEndIndex: String.Index) -> ParsicleStatus<Value> {
    return ParsicleStatus(input: input, matchEndIndex: matchEndIndex, value: value)
  }
}

public struct ParsicleContext {
  /// Flag indicating the current parse operation is only used for matching, and any processing and transformation of values etc can thus be skipped to optimize performance.
  public let matchOnly: Bool
  public let userInfo: Any?
}

public extension ParsicleContext {
  init() {
    self.init(matchOnly: false, userInfo: nil)
  }
  init(matchOnly: Bool) {
    self.init(matchOnly: matchOnly, userInfo: nil)
  }
  init(userInfo: Any?) {
    self.init(matchOnly: false, userInfo: userInfo)
  }
  
  func onlyMatching() -> ParsicleContext {
    return ParsicleContext(matchOnly: true, userInfo: userInfo)
  }
}


public typealias Parsicles = Parsicle<Any>
public typealias AnyParsicle = Parsicle<Any>
public typealias StringParsicle = Parsicle<String>
public let PassThroughParsicle = StringParsicle(name: "PassThroughParsicle") { input, _ in return ParsicleStatus(input: input, matchEndIndex: input.endIndex, value: String(input))
}

public typealias ParsicleBlock<Result> = (_ input: Substring, _ context: ParsicleContext) -> ParsicleStatus<Result>


// MARK: - ParsicleType

/**
 * ParsicleType
 */
public protocol ParsicleType {
  associatedtype ParserResult
  
  func parse(_ string: Substring, context: ParsicleContext) -> ParsicleStatus<ParserResult>
}

public extension ParsicleType {
  func asParsicle() -> Parsicle<ParserResult> {
    return Parsicle(self)
  }
}


// MARK: - Parsicle

open class Parsicle<Value>: ParsicleType, CustomStringConvertible, CustomDebugStringConvertible {
  public typealias ParserResult = Value
  
  private let parserBlock: ParsicleBlock<Value>
  
  let name: String?
  public var description: String { return name ?? "Parsicle(\(String(describing: Value.self)))" }
  public var debugDescription: String {
    if let name = name { return "\(name) (\(String(describing: Value.self)))" }
    else { return "Parsicle(\(String(describing: Value.self)))" }
  }
  
  public init<P: ParsicleType>(_ parsicleType: P, name: String? = nil) where P.ParserResult == Value {
    parserBlock = parsicleType.parse
    self.name = name
  }
  
  public init(name: String? = nil, parserBlock: @escaping ParsicleBlock<Value>) {
    self.parserBlock = parserBlock
    self.name = name
  }
  
  public func parse(_ string: Substring, context: ParsicleContext = ParsicleContext()) -> ParsicleStatus<ParserResult> {
    return parserBlock(string, context)
  }
}

public extension Parsicle {
  func parse(_ string: Substring, userInfo: Any?) -> ParsicleStatus<ParserResult> {
    return parse(string, context: ParsicleContext(userInfo: userInfo))
  }
  
  func parse(_ string: String, context: ParsicleContext = ParsicleContext()) -> ParsicleStatus<ParserResult> {
    return parse(string[string.startIndex...], context: context)
  }
  
  func parse(_ string: String, userInfo: Any?) -> ParsicleStatus<ParserResult> {
    return parse(string, context: ParsicleContext(userInfo: userInfo))
  }
  
  func matches(_ string: String) -> Bool {
    let status = parse(string[string.startIndex...], context: ParsicleContext(matchOnly: true))
    return status.match && status.residual.count == 0
  }
}

public class NoParsicle<Value>: Parsicle<Value> {
  public init() {
    super.init() { input, _ in return ParsicleStatus(input) }
  }
}

public class DelegatingParsicle<Value>: Parsicle<Value> {
  public var delegate: Parsicle<Value>?
  
  public init() {
    super.init(NoParsicle(), name: "DelegatingParsicle")
  }
  
  override public func parse(_ string: Substring, context: ParsicleContext) -> ParsicleStatus<ParserResult> {
    guard let delegate = delegate else { return super.parse(string, context: context) }
    return delegate.parse(string, context: context)
  }
}
