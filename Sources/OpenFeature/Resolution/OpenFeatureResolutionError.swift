//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenFeature open source project
//
// Copyright (c) 2024 the Swift OpenFeature project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public struct OpenFeatureResolutionError: Error, Equatable {
    public let code: Code
    public let message: String?

    public init(code: Code, message: String?) {
        self.code = code
        self.message = message
    }

    public struct Code: RawRepresentable, Sendable, Equatable {
        public static let providerNotReady = Code(rawValue: "PROVIDER_NOT_READY")
        public static let fatal = Code(rawValue: "PROVIDER_FATAL")
        public static let flagNotFound = Code(rawValue: "FLAG_NOT_FOUND")
        public static let parseError = Code(rawValue: "PARSE_ERROR")
        public static let typeMismatch = Code(rawValue: "TYPE_MISMATCH")
        public static let targetingKeyMissing = Code(rawValue: "TARGETING_KEY_MISSING")
        public static let invalidContext = Code(rawValue: "INVALID_CONTEXT")
        public static let general = Code(rawValue: "GENERAL")

        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}
