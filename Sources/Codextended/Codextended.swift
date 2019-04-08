/**
 *  Codextended
 *  Copyright (c) John Sundell 2019
 *  Licensed under the MIT license (see LICENSE file)
 */

import Foundation

// MARK: - Encoding

/// Protocol acting as a common API for all types of encoders,
/// such as `JSONEncoder` and `PropertyListEncoder`.
public protocol AnyEncoder {
    /// Encode a given value into binary data.
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONEncoder: AnyEncoder {}

#if canImport(ObjectiveC)
extension PropertyListEncoder: AnyEncoder {}
#endif

public extension Encodable {
    /// Encode this value, optionally using a specific encoder.
    /// If no explicit encoder is passed, then the value is encoded into JSON.
    func encoded(using encoder: AnyEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }
}

public extension Encoder {
    /// Encode a singular value into this encoder.
    func encodeSingleValue<T: Encodable>(_ value: T) throws {
        var container = singleValueContainer()
        try container.encode(value)
    }

    /// Encode a value for a given key, specified as a string.
    func encode<T: Encodable>(_ value: T, for key: String) throws {
        try encode(value, for: AnyCodingKey(key))
    }

    /// Encode a value for a given key, specified as a `CodingKey`.
    func encode<T: Encodable, K: CodingKey>(_ value: T, for key: K) throws {
        var container = self.container(keyedBy: K.self)
        try container.encode(value, forKey: key)
    }

    /// Encode a date for a given key (specified as a string), using a specific formatter.
    /// To encode a date without using a specific formatter, simply encode it like any other value.
    func encode(_ date: Date, for key: String, using formatter: DateFormatter) throws {
        try encode(date, for: AnyCodingKey(key), using: formatter)
    }

    /// Encode a date for a given key (specified using a `CodingKey`), using a specific formatter.
    /// To encode a date without using a specific formatter, simply encode it like any other value.
    func encode<K: CodingKey>(_ date: Date, for key: K, using formatter: DateFormatter) throws {
        let string = formatter.string(from: date)
        try encode(string, for: key)
    }
}

// MARK: - Decoding

/// Protocol acting as a common API for all types of decoders,
/// such as `JSONDecoder` and `PropertyListDecoder`.
public protocol AnyDecoder {
    /// Decode a value of a given type from binary data.
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONDecoder: AnyDecoder {}

#if canImport(ObjectiveC)
extension PropertyListDecoder: AnyDecoder {}
#endif

public extension Data {
    /// Decode this data into a value, optionally using a specific decoder.
    /// If no explicit encoder is passed, then the data is decoded as JSON.
    func decoded<T: Decodable>(as type: T.Type = T.self,
                               using decoder: AnyDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(T.self, from: self)
    }
}

public extension Decoder {
    /// Decode a singular value from the underlying data.
    func decodeSingleValue<T: Decodable>(as type: T.Type = T.self) throws -> T {
        let container = try singleValueContainer()
        return try container.decode(type)
    }

    /// Decode a value for a given key, specified as a string.
    func decode<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try decode(AnyCodingKey(key), as: type)
    }

    /// Deceode a value for a given key, specified as a `CodingKey`.
    func decode<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T {
        let container = try self.container(keyedBy: K.self)
        return try container.decode(type, forKey: key)
    }

    /// Decode a date from a string for a given key (specified as a string), using a
    /// specific formatter. To decode a date using the decoder's default settings,
    /// simply decode it like any other value instead of using this method.
    func decode(_ key: String, using formatter: DateFormatter) throws -> Date {
        return try decode(AnyCodingKey(key), using: formatter)
    }

    /// Decode a date from a string for a given key (specified as a `CodingKey`), using
    /// a specific formatter. To decode a date using the decoder's default settings,
    /// simply decode it like any other value instead of using this method.
    func decode<K: CodingKey>(_ key: K, using formatter: DateFormatter) throws -> Date {
        let container = try self.container(keyedBy: K.self)
        let rawString = try container.decode(String.self, forKey: key)

        guard let date = formatter.date(from: rawString) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Unable to format date string"
            )
        }

        return date
    }
}

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        stringValue = string
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

// MARK: - Transformable

/// The Transformable typealias which is the protocol composition of `EncodeTransformable` and `DecodeTransformable`
public typealias Transformable = EncodeTransformable & DecodeTransformable

// MARK: - EncodeTransformable

/// The EncodeTransformable acting as a value-converter to
/// transform a given SourceType to an Encodable TargetType
public protocol EncodeTransformable {
    
    /// The EncodeSourceType
    associatedtype EncodeSourceType
    
    /// The EncodeTargetType which must be conform to Encodable
    associatedtype EncodeTargetType: Encodable
    
    /// Transform the SourceType value to the Encodable TargetType
    ///
    /// - Parameter value: The EncodeSourceType value
    /// - Returns: The transformed Encodable TargetType
    func transformToEncodable(value: EncodeSourceType) -> EncodeTargetType
    
}

// MARK: - DecodeTransformable

/// The DecodeTranformable acting as a value-converter to
/// transform a given DecodeSourceType to an DecodeTargetType
public protocol DecodeTransformable {
    
    /// The DecodeSourceType which mus be conform to Decodable
    associatedtype DecodeSourceType: Decodable
    
    /// The DecodeTargetType
    associatedtype DecodeTargetType
    
    /// Transform the decodable SourceType value to the TargetType
    ///
    /// - Parameter decodedValue: The decodable value
    /// - Returns: The transformed Decode TargetType
    func transformFromDecodable(value: DecodeSourceType) -> DecodeTargetType
    
}
