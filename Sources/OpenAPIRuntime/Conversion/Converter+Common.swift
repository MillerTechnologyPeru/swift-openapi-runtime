//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import Foundation

extension Converter {

    // MARK: Miscs

    /// Returns the MIME type from the content-type header, if present.
    /// - Parameter headerFields: The header fields to inspect for the content
    /// type header.
    /// - Returns: The content type value, or nil if not found or invalid.
    public func extractContentTypeIfPresent(in headerFields: [HeaderField]) -> OpenAPIMIMEType? {
        guard let rawValue = headerFields.firstValue(name: "content-type") else {
            return nil
        }
        return OpenAPIMIMEType(rawValue)
    }

    /// Checks whether a concrete content type matches an expected content type.
    ///
    /// The concrete content type can contain parameters, such as `charset`, but
    /// they are ignored in the equality comparison.
    ///
    /// The expected content type can contain wildcards, such as */* and text/*.
    /// - Parameters:
    ///   - received: The concrete content type to validate against the other.
    ///   - expectedRaw: The expected content type, can contain wildcards.
    /// - Throws: A `RuntimeError` when `expectedRaw` is not a valid content type.
    /// - Returns: A Boolean value representing whether the concrete content
    /// type matches the expected one.
    public func isMatchingContentType(received: OpenAPIMIMEType?, expectedRaw: String) throws -> Bool {
        guard let received else {
            return false
        }
        guard case let .concrete(type: receivedType, subtype: receivedSubtype) = received.kind else {
            return false
        }
        guard let expectedContentType = OpenAPIMIMEType(expectedRaw) else {
            throw RuntimeError.invalidExpectedContentType(expectedRaw)
        }
        switch expectedContentType.kind {
        case .any:
            return true
        case .anySubtype(let expectedType):
            return receivedType.lowercased() == expectedType.lowercased()
        case .concrete(let expectedType, let expectedSubtype):
            return receivedType.lowercased() == expectedType.lowercased()
                && receivedSubtype.lowercased() == expectedSubtype.lowercased()
        }
    }

    /// Returns an error to be thrown when an unexpected content type is
    /// received.
    /// - Parameter contentType: The content type that was received.
    public func makeUnexpectedContentTypeError(contentType: OpenAPIMIMEType?) -> any Error {
        RuntimeError.unexpectedContentTypeHeader(contentType?.description ?? "")
    }

    // MARK: - Converter helper methods

    //    | common | set | header field | URI | both | setHeaderFieldAsURI |
    public func setHeaderFieldAsURI<T: Encodable>(
        in headerFields: inout [HeaderField],
        name: String,
        value: T?
    ) throws {
        guard let value else {
            return
        }
        try setHeaderField(
            in: &headerFields,
            name: name,
            value: value,
            convert: { value in
                try convertToURI(
                    style: .simple,
                    explode: false,
                    inBody: false,
                    key: "",
                    value: value
                )
            }
        )
    }

    //    | common | set | header field | JSON | both | setHeaderFieldAsJSON |
    public func setHeaderFieldAsJSON<T: Encodable>(
        in headerFields: inout [HeaderField],
        name: String,
        value: T?
    ) throws {
        try setHeaderField(
            in: &headerFields,
            name: name,
            value: value,
            convert: convertHeaderFieldCodableToJSON
        )
    }

    //    | common | get | header field | URI | optional | getOptionalHeaderFieldAsURI |
    public func getOptionalHeaderFieldAsURI<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: { encodedValue in
                try convertFromURI(
                    style: .simple,
                    explode: false,
                    inBody: false,
                    key: "",
                    encodedValue: encodedValue
                )
            }
        )
    }

    //    | common | get | header field | URI | required | getRequiredHeaderFieldAsURI |
    public func getRequiredHeaderFieldAsURI<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: { encodedValue in
                try convertFromURI(
                    style: .simple,
                    explode: false,
                    inBody: false,
                    key: "",
                    encodedValue: encodedValue
                )
            }
        )
    }

    //    | common | get | header field | JSON | optional | getOptionalHeaderFieldAsJSON |
    public func getOptionalHeaderFieldAsJSON<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertJSONToHeaderFieldCodable
        )
    }

    //    | common | get | header field | JSON | required | getRequiredHeaderFieldAsJSON |
    public func getRequiredHeaderFieldAsJSON<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertJSONToHeaderFieldCodable
        )
    }
}
