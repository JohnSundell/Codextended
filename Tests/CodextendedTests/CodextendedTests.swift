/**
 *  Codextended
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE file)
 */

import XCTest
import Codextended

final class CodextendedTests: XCTestCase {
    func testEncodingAndDecoding() throws {
        struct Value: Codable, Equatable {
            let string: String
        }

        let valueA = Value(string: "Hello, world!")
        let data = try valueA.encoded()
        let valueB = try data.decoded() as Value
        XCTAssertEqual(valueA, valueB)
    }

    func testDecodeIfPresent() throws {
        struct Value: Decodable, Equatable {
            let stringA: String?
            let stringB: String?

            init(from decoder: Decoder) throws {
                stringA = try decoder.decodeIfPresent("stringA")
                stringB = try decoder.decodeIfPresent("stringB")
            }
        }

        let value = try Data(#"{"stringA": "stringA"}"#.utf8).decoded() as Value
        XCTAssertEqual(value.stringA, "stringA")
        XCTAssertNil(value.stringB)
    }

    func testDecodeIfPresentTypeMismatch() throws {
        struct Value: Decodable, Equatable {
            let string: String?

            init(from decoder: Decoder) throws {
                string = try decoder.decodeIfPresent("string")
            }
        }

        do {
            let _ = try Data(#"{"string": 123}"#.utf8).decoded() as Value
            XCTFail("Decoding expected to fail due to type mismatch.")
        } catch DecodingError.typeMismatch {
            return
        } catch {
            XCTFail("Expected `typeMismatch` error.")
        }
    }

    func testSingleValue() throws {
        struct Value: Codable, Equatable {
            let string: String

            init(string: String) {
                self.string = string
            }

            init(from decoder: Decoder) throws {
                string = try decoder.decodeSingleValue()
            }

            func encode(to encoder: Encoder) throws {
                try encoder.encodeSingleValue(string)
            }
        }

        let valuesA = [Value(string: "Hello, world!")]
        let data = try valuesA.encoded()
        let valuesB = try data.decoded() as [Value]
        XCTAssertEqual(valuesA, valuesB)
    }

    func testUsingStringAsKey() throws {
        struct Value: Codable, Equatable {
            let string: String

            init(string: String) {
                self.string = string
            }

            init(from decoder: Decoder) throws {
                string = try decoder.decode("key")
            }

            func encode(to encoder: Encoder) throws {
                try encoder.encode(string, for: "key")
            }
        }

        let valueA = Value(string: "Hello, world!")
        let data = try valueA.encoded()
        let valueB = try data.decoded() as Value
        XCTAssertEqual(valueA, valueB)
    }

    func testUsingCodingKey() throws {
        struct Value: Codable, Equatable {
            enum CodingKeys: CodingKey {
                case key
            }

            let string: String

            init(string: String) {
                self.string = string
            }

            init(from decoder: Decoder) throws {
                string = try decoder.decode(CodingKeys.key)
            }

            func encode(to encoder: Encoder) throws {
                try encoder.encode(string, for: CodingKeys.key)
            }
        }

        let valueA = Value(string: "Hello, world!")
        let data = try valueA.encoded()
        let valueB = try data.decoded() as Value
        XCTAssertEqual(valueA, valueB)
    }

    func testDateWithCustomFormatter() throws {
        struct Value: Codable, Equatable {
            static func makeDateFormatter() -> DateFormatter {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }

            let date: Date

            init(date: Date) {
                self.date = date
            }

            init(from decoder: Decoder) throws {
                let formatter = Value.makeDateFormatter()
                date = try decoder.decode("key", using: formatter)
            }

            func encode(to encoder: Encoder) throws {
                let formatter = Value.makeDateFormatter()
                try encoder.encode(date, for: "key", using: formatter)
            }
        }

        let valueA = Value(date: Date())
        let data = try valueA.encoded()
        let valueB = try data.decoded() as Value
        let formatter = Value.makeDateFormatter()

        XCTAssertEqual(formatter.string(from: valueA.date),
                       formatter.string(from: valueB.date))
    }

    @available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
    func testDateWithISO8601Formatter() throws {
        struct Value: Codable, Equatable {
            let date: Date

            init(date: Date) {
                self.date = date
            }

            init(from decoder: Decoder) throws {
                let formatter = ISO8601DateFormatter()
                date = try decoder.decode("key", using: formatter)
            }

            func encode(to encoder: Encoder) throws {
                let formatter = ISO8601DateFormatter()
                try encoder.encode(date, for: "key", using: formatter)
            }
        }

        let valueA = Value(date: Date())
        let data = try valueA.encoded()
        let valueB = try data.decoded() as Value
        let formatter = ISO8601DateFormatter()

        XCTAssertEqual(formatter.string(from: valueA.date),
                       formatter.string(from: valueB.date))
    }

    func testDecodingErrorThrownForInvalidDateString() {
        struct Value: Decodable {
            let date: Date

            init(date: Date) {
                self.date = date
            }

            init(from decoder: Decoder) throws {
                date = try decoder.decode("key", using: DateFormatter())
            }
        }

        let data = Data(#"{"key": "notADate"}"#.utf8)

        XCTAssertThrowsError(try data.decoded() as Value) { error in
            XCTAssertTrue(error is DecodingError,
                          "Expected DecodingError but got \(type(of: error))")
        }
    }

    func testAllTestsRunOnLinux() {
        verifyAllTestsRunOnLinux(excluding: ["testDateWithISO8601Formatter"])
    }
}

extension CodextendedTests: LinuxTestable {
    static var allTests = [
        ("testEncodingAndDecoding", testEncodingAndDecoding),
        ("testDecodeIfPresent", testDecodeIfPresent),
        ("testDecodeIfPresentTypeMismatch", testDecodeIfPresentTypeMismatch),
        ("testSingleValue", testSingleValue),
        ("testUsingStringAsKey", testUsingStringAsKey),
        ("testUsingCodingKey", testUsingCodingKey),
        ("testDateWithCustomFormatter", testDateWithCustomFormatter),
        ("testDecodingErrorThrownForInvalidDateString", testDecodingErrorThrownForInvalidDateString)
    ]
}
