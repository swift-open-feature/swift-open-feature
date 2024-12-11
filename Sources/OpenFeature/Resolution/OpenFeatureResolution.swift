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

public struct OpenFeatureResolution<Value: OpenFeatureValue>: Sendable {
    public let value: Value
    public let error: OpenFeatureResolutionError?
    public let reason: OpenFeatureResolutionReason?
    public let variant: String?
    public let flagMetadata: [String: OpenFeatureFlagMetadataValue]

    public init(
        value: Value,
        error: OpenFeatureResolutionError? = nil,
        reason: OpenFeatureResolutionReason? = nil,
        variant: String? = nil,
        flagMetadata: [String: OpenFeatureFlagMetadataValue] = [:]
    ) {
        self.value = value
        self.error = error
        self.reason = reason
        self.variant = variant
        self.flagMetadata = flagMetadata
    }
}

extension OpenFeatureResolution: Equatable where Value: Equatable {}
