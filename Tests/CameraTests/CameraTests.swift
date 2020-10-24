import XCTest
@testable import Camera

final class CameraTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Camera().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
