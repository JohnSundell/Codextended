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

#if canImport(ObjectiveC) || swift(>=5.1)
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

#if canImport(ObjectiveC) || swift(>=5.1)
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

    /// Decode a value for a given key, specified as a `CodingKey`.
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





enum CodingError : Error {
    case RuntimeError(String)
}

struct AnyKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// Just a sample codingStrategy that could be used.
public var customCodingStrategy: JSONDecoder.KeyDecodingStrategy = .custom { keys in
    let lastComponent = keys.last!.stringValue
    let snakeCased = lastComponent.split(separator: "_").map { $0.prefix(1).uppercased() + $0.dropFirst() }.reduce("") { $0 + $1}
    let lowerFirst = snakeCased.prefix(1).lowercased() + snakeCased.dropFirst()
    return AnyKey(stringValue: lowerFirst)
}

public extension Encodable {
    /**
     Convert this object to json data
     
     - parameter outputFormatting: The formatting of the output JSON data (compact or pritty printed)
     - parameter dateEncodinStrategy: how do you want to format the date
     - parameter dataEncodingStrategy: what kind of encoding. base64 is the default
     
     - returns: The json data
     */
    func toJsonData(outputFormatting: JSONEncoder.OutputFormatting = [], dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate, dataEncodingStrategy: JSONEncoder.DataEncodingStrategy = .base64) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        encoder.dateEncodingStrategy = dateEncodingStrategy
        encoder.dataEncodingStrategy = dataEncodingStrategy
        return try? encoder.encode(self)
    }
    
    /**
     Convert this object to a json string
     
     - parameter outputFormatting: The formatting of the output JSON data (compact or pritty printed)
     - parameter dateEncodinStrategy: how do you want to format the date
     - parameter dataEncodingStrategy: what kind of encoding. base64 is the default
     
     - returns: The json string
     */
    func toJsonString(outputFormatting: JSONEncoder.OutputFormatting = [], dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate, dataEncodingStrategy: JSONEncoder.DataEncodingStrategy = .base64) -> String? {
        let data = self.toJsonData(outputFormatting: outputFormatting, dateEncodingStrategy: dateEncodingStrategy, dataEncodingStrategy: dataEncodingStrategy)
        return data == nil ? nil : String(data: data!, encoding: .utf8)
    }
    
    
    /**
     Save this object to a file in the temp directory
     
     - parameter fileName: The filename
     
     - returns: Nothing
     */
    func saveTo(_ fileURL: URL) throws {
        guard let data = self.toJsonData() else { throw CodingError.RuntimeError("cannot create data from object")}
        try data.write(to: fileURL, options: .atomic)
    }
    
    
    /**
     Save this object to a file in the temp directory
     
     - parameter fileName: The filename
     
     - returns: Nothing
     */
    func saveToTemp(_ fileName: String) throws {
        let fileURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        try self.saveTo(fileURL)
    }
    
    
    
    #if os(tvOS)
    // Save to documents folder is not supported on tvOS
    #else
    /**
     Save this object to a file in the documents directory
     
     - parameter fileName: The filename
     
     - returns: true if successfull
     */
    func saveToDocuments(_ fileName: String) throws {
        let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        try self.saveTo(fileURL)
    }
    #endif
}

public extension Decodable {
    /**
     Create an instance of this type from a json string
     
     - parameter json: The json string
     - parameter keyPath: for if you want something else than the root object
     */
    init(json: String, keyPath: String? = nil,
         keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
         dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
         dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64,
         nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .throw) throws {
        guard let data = json.data(using: .utf8) else { throw CodingError.RuntimeError("cannot create data from string") }
        try self.init(data: data, keyPath: keyPath, keyDecodingStrategy: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy, dataDecodingStrategy: dataDecodingStrategy, nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy)
    }
    
    /**
     Create an instance of this type from a json string
     
     - parameter data: The json data
     - parameter keyPath: for if you want something else than the root object
     */
    init(data: Data, keyPath: String? = nil,
         keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
         dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
         dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64,
         nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .throw) throws {

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.dataDecodingStrategy = dataDecodingStrategy
        decoder.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy

        if let keyPath = keyPath {
            let topLevel = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
            guard let nestedJson = (topLevel as AnyObject).value(forKeyPath: keyPath) else { throw CodingError.RuntimeError("Cannot decode data to object")  }
            let nestedData = try JSONSerialization.data(withJSONObject: nestedJson)
            self = try decoder.decode(Self.self, from: nestedData)
            return
        }
        self = try decoder.decode(Self.self, from: data)
    }
    
    /**
     Initialize this object from an archived file from an URL
     
     - parameter fileNameInTemp: The filename
     */
    init(fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        try self.init(data: data)
    }
    
    /**
     Initialize this object from an archived file from the temp directory
     
     - parameter fileNameInTemp: The filename
     */
    init(fileNameInTemp: String) throws {
        let fileURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileNameInTemp)
        try self.init(fileURL: fileURL)
    }
    
    /**
     Initialize this object from an archived file from the documents directory
     
     - parameter fileNameInDocuments: The filename
     */
    init(fileNameInDocuments: String) throws {
        let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileNameInDocuments)
        try self.init(fileURL: fileURL)
    }
}
