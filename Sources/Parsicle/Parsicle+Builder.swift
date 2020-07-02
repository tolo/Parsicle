//
//  Parsicle+Builder.swift
//  Parsicle
//
//  Created by Tobias on 2019-09-26.
//

import Foundation
import Combine


@_functionBuilder
public class ParsicleBuilder {
  
  public typealias Expression = AnyParsicle
  
  public typealias Component = [AnyParsicle]
  
  public static func buildBlock(_ parsers: Component...) -> Component {
    return parsers.flatMap { $0 }
  }
  
  static func buildBlock(_ component: Component) -> Component {
    return component
  }
  
  static func buildExpression(_ expression: Expression) -> Component {
    return [expression]
  }
  
  static func buildExpression(_ expression: Character) -> Component {
    return [Char(expression).asAny()]
  }
  
  static func buildExpression(_ expression: String) -> Component {
    return [String(expression).asAny()]
  }
    
  static func buildExpression<T>(_ expression: Parsicle<T>) -> Component {
    return [expression.asAny()]
  }
  
  static func buildOptional(_ children: Component?) -> Component {
    return children ?? []
  }
}


public func Char(_ character: Character, skipSpaces: Bool = false) -> StringParsicle {
  return StringParsicle.char(character, skipSpaces: skipSpaces)
}

public func String(_ string: String, ignoreCase: Bool = true, skipSpaces: Bool = false) -> StringParsicle {
  return StringParsicle.string(string, ignoreCase: ignoreCase, skipSpaces: skipSpaces)
}

public func Space() -> StringParsicle {
  return Parsicles.space()
}

public func Spaces(_ minCount: Int = 0) -> StringParsicle {
  return Parsicles.spaces(minCount)
}

public func Digit() -> StringParsicle {
  return Parsicles.digit()
}

public func Digits(_ minCount: Int = 0) -> StringParsicle {
  return Parsicles.digits(minCount)
}

public func Take(untilIn characterSet: CharacterSet, minCount: Int = 0) -> StringParsicle {
  return Parsicles.take(untilIn: characterSet, minCount: minCount)
}

public func Take(untilChar character: Character, andSkip skip: Bool = false, minCount: Int = 0) -> StringParsicle {
  return Parsicles.take(untilChar: character, andSkip: skip, minCount: minCount)
}

public func Take(untilString string: String, andSkip skip: Bool = false) -> StringParsicle {
  return Parsicles.take(untilString: string, andSkip: skip)
}

public func Take(whileIn characterSet: CharacterSet, withInitialCharSet initialCharSet: CharacterSet? = nil, minCount: Int = 0) -> StringParsicle {
  return Parsicles.take(whileIn: characterSet, withInitialCharSet: initialCharSet, minCount: minCount)
}

public func Choice(@ParsicleBuilder _ content: () -> [AnyParsicle]) -> AnyParsicle {
  return Parsicles.choice(content())
}

public func Choice<Result>(@ParsicleBuilder _ content: () -> [Parsicle<Result>]) -> Parsicle<Result> {
  return Parsicles.choice(content())
}

public func Choice<Result>(_ parsers: [Parsicle<Result>]) -> Parsicle<Result> {
  return Parsicles.choice(parsers)
}

public func Sequential(@ParsicleBuilder _ content: () -> [AnyParsicle]) -> AnyParsicle {
  return Parsicles.sequential(content()).asAny()
}

public func Sequential<Result>(_ parsers: [Parsicle<Result>]) -> Parsicle<[Result]> {
  return Parsicles.sequential(parsers)
}
