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

public struct OpenFeatureEvaluationContext: Sendable {
    public var targetingKey: String?
    public var fields: [String: OpenFeatureFieldValue]

    public init(targetingKey: String? = nil, fields: [String: OpenFeatureFieldValue] = [:]) {
        self.targetingKey = targetingKey
        self.fields = fields
    }

    public mutating func merge(_ other: OpenFeatureEvaluationContext) {
        targetingKey = other.targetingKey ?? targetingKey
        fields.merge(other.fields, uniquingKeysWith: { $1 })
    }
}
