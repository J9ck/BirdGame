import XCTest
@testable import BirdGame3Tests

fileprivate extension BirdSkillTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__BirdSkillTests = [
        ("testBirdSkillInitialization", testBirdSkillInitialization),
        ("testStaticSkills", testStaticSkills)
    ]
}

fileprivate extension BirdTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__BirdTests = [
        ("testBirdInitialization", testBirdInitialization),
        ("testHealthPercentage", testHealthPercentage),
        ("testIsAlive", testIsAlive),
        ("testStaticBirds", testStaticBirds)
    ]
}

fileprivate extension ControlInputTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__ControlInputTests = [
        ("testDefaultInitialization", testDefaultInitialization),
        ("testNormalizedMovement", testNormalizedMovement),
        ("testSpeedMultiplier", testSpeedMultiplier)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __BirdGame3Tests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BirdSkillTests.__allTests__BirdSkillTests),
        testCase(BirdTests.__allTests__BirdTests),
        testCase(ControlInputTests.__allTests__ControlInputTests)
    ]
}