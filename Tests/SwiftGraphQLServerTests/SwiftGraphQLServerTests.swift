import XCTest
@testable import SwiftGraphQLServer

final class SwiftGraphQLServerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftGraphQLServer().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
