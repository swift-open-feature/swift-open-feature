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

public struct OpenFeatureClient: Sendable {
    private let provider: any OpenFeatureProvider

    public func value(
        for flag: String,
        defaultingTo defaultValue: Bool,
        context: OpenFeatureEvaluationContext? = nil,
        options: OpenFeatureEvaluationOptions? = nil
    ) async -> Bool {
        let resolution = await provider.resolution(of: flag, defaultValue: defaultValue, context: context)
        return resolution.value
    }

    public func evaluation(
        of flag: String,
        defaultingTo defaultValue: Bool,
        context: OpenFeatureEvaluationContext? = nil,
        options: OpenFeatureEvaluationOptions? = nil
    ) async -> OpenFeatureEvaluation<Bool> {
        let resolution = await provider.resolution(of: flag, defaultValue: defaultValue, context: context)
        return OpenFeatureEvaluation(flag: flag, resolution: resolution)
    }

    init(provider: any OpenFeatureProvider) {
        self.provider = provider
    }
}
