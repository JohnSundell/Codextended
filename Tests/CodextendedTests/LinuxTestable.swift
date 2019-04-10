/**
 *  Codextended
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE.md)
 */

import XCTest

protocol LinuxTestable: XCTestCase {
    static var allTests: [(String, (Self) -> () throws -> Void)] { get }
}

extension LinuxTestable {
    func verifyAllTestsRunOnLinux(excluding excludedTestNames: Set<String>) {
        #if os(macOS)
        let testNames = Set(Self.allTests.map { $0.0 })

        for name in Self.testNames {
            guard name != "testAllTestsRunOnLinux" else {
                continue
            }

            guard !excludedTestNames.contains(name) else {
                continue
            }

            if !testNames.contains(name) {
                XCTFail("""
                Test case \(Self.self) does not include test \(name) on Linux.
                Please add it to the test case's 'allTests' array.
                """)
            }
        }
        #endif
    }
}

#if os(macOS)
private extension LinuxTestable {
    static var testNames: [String] {
        return defaultTestSuite.tests.map { test in
            let components = test.name.components(separatedBy: .whitespaces)
            return components[1].replacingOccurrences(of: "]", with: "")
        }
    }
}
#endif
