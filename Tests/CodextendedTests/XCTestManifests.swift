/**
 *  Codextended
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE file)
 */

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CodextendedTests.allTests),
    ]
}
#endif
