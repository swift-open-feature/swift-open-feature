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

public struct OpenFeatureResolutionReason: RawRepresentable, Sendable, Equatable {
    public static let `default` = OpenFeatureResolutionReason(rawValue: "DEFAULT")
    public static let targetingMatch = OpenFeatureResolutionReason(rawValue: "TARGETING_MATCH")
    public static let split = OpenFeatureResolutionReason(rawValue: "SPLIT")
    public static let disabled = OpenFeatureResolutionReason(rawValue: "DISABLED")
    public static let `static` = OpenFeatureResolutionReason(rawValue: "STATIC")
    public static let cached = OpenFeatureResolutionReason(rawValue: "CACHED")
    public static let unknown = OpenFeatureResolutionReason(rawValue: "UNKNOWN")
    public static let error = OpenFeatureResolutionReason(rawValue: "ERROR")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
