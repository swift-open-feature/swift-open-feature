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

public struct OpenFeatureHookContext: Sendable {
    public let flag: String
    public let defaultValue: any OpenFeatureValue
    public var evaluationContext: OpenFeatureEvaluationContext
    public let providerMetadata: OpenFeatureProviderMetadata?

    public init(
        flag: String,
        defaultValue: some OpenFeatureValue,
        evaluationContext: OpenFeatureEvaluationContext,
        providerMetadata: OpenFeatureProviderMetadata?
    ) {
        self.flag = flag
        self.defaultValue = defaultValue
        self.evaluationContext = evaluationContext
        self.providerMetadata = providerMetadata
    }
}
