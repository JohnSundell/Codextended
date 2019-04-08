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

    /// Encode a value for a given key (specified as a string), using a concrete EncodeTransformable.
    ///
    /// - Parameters:
    ///   - value: The value
    ///   - key: The key as a string
    ///   - transformable: The concrete EncodeTransformable
    /// - Throws: If encoding fails
    func encode<T: EncodeTransformable>(_ value: T.EncodeSourceType, for key: String, using transformable: T) throws {
        try encode(value, for: AnyCodingKey(key), using: transformable)
    }
    
    /// Encode a value for a given key (specified using a `CodingKey`), using a concrete EncodeTransformable
    ///
    /// - Parameters:
    ///   - value: The value
    ///   - key: The CodingKey
    ///   - transformable: The concrete EncodeTransformable
    /// - Throws: If encoding fails
    func encode<K: CodingKey, T: EncodeTransformable>(_ value: T.EncodeSourceType, for key: K, using transformable: T) throws {
        let encodableValue = try transformable.transformToEncodable(value: value)
        try encode(encodableValue, for: key)
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

    /// Decode a value for a given key specified as a string), using a concrete DecodeTransformable
    ///
    /// - Parameters:
    ///   - key: The key as a string
    ///   - transformable: The concrete DecodeTransformable
    /// - Returns: The DecodeTransformable TargetType value
    /// - Throws: If decoding fails
    func decode<T: DecodeTransformable>(_ key: String, using transformable: T) throws -> T.DecodeTargetType {
        return try decode(AnyCodingKey(key), using: transformable)
    }
    
    /// Decode a value for a given key specified as a `CodingKey`), using a concrete DecodeTransformable
    ///
    /// - Parameters:
    ///   - key: The CodingKey
    ///   - transformable: The concrete DecodeTransformable
    /// - Returns: The DecodeTransformable TargetType value
    /// - Throws: If decoding fails
    func decode<K: CodingKey, T: DecodeTransformable>(_ key: K, using transformable: T) throws -> T.DecodeTargetType {
        let container = try self.container(keyedBy: K.self)
        let decodedValue = try container.decode(T.DecodeSourceType.self, forKey: key)
        return try transformable.transformFromDecodable(value: decodedValue)
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
    /// - Throws: If transforming fails
    func transformToEncodable(value: EncodeSourceType) throws -> EncodeTargetType
    
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
    /// - Throws: If transforming fails
    func transformFromDecodable(value: DecodeSourceType) throws -> DecodeTargetType
    
}

// MARK: - DateFormatter+Transformable

extension DateFormatter: Transformable {
    
    public func transformToEncodable(value: Date) throws -> String {
        return self.string(from: value)
    }
    
    public func transformFromDecodable(value: String) throws -> Date? {
        return self.date(from: value)
    }
    
}
