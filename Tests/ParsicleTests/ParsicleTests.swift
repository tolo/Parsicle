import XCTest
@testable import Parsicle

final class ParsicleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Parsicle().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
