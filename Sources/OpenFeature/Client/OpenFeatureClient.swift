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

public actor OpenFeatureClient: Sendable {
    private let provider: () -> any OpenFeatureProvider
    private let globalEvaluationContext: () -> OpenFeatureEvaluationContext?
    private var evaluationContext: OpenFeatureEvaluationContext?

    public func value(
        for flag: String,
        defaultingTo defaultValue: Bool,
        context: OpenFeatureEvaluationContext? = nil,
        options: OpenFeatureEvaluationOptions? = nil
    ) async -> Bool {
        let context = mergedEvaluationContext(invocationContext: context)
        let resolution = await provider().resolution(of: flag, defaultValue: defaultValue, context: context)
        return resolution.value
    }

    public func evaluation(
        of flag: String,
        defaultingTo defaultValue: Bool,
        context: OpenFeatureEvaluationContext? = nil,
        options: OpenFeatureEvaluationOptions? = nil
    ) async -> OpenFeatureEvaluation<Bool> {
        let context = mergedEvaluationContext(invocationContext: context)
        let resolution = await provider().resolution(of: flag, defaultValue: defaultValue, context: context)
        return OpenFeatureEvaluation(flag: flag, resolution: resolution)
    }

    public func setEvaluationContext(_ evaluationContext: OpenFeatureEvaluationContext?) {
        self.evaluationContext = evaluationContext
    }

    package init(
        provider: @escaping () -> any OpenFeatureProvider,
        globalEvaluationContext: @escaping () -> OpenFeatureEvaluationContext? = { nil },
        evaluationContext: OpenFeatureEvaluationContext? = nil
    ) {
        self.evaluationContext = evaluationContext
        self.globalEvaluationContext = globalEvaluationContext
        self.provider = provider
    }

    private func mergedEvaluationContext(
        invocationContext: OpenFeatureEvaluationContext?
    ) -> OpenFeatureEvaluationContext? {
        var context = globalEvaluationContext() ?? OpenFeatureEvaluationContext()

        if let taskLocalContext = OpenFeatureEvaluationContext.current {
            context.merge(taskLocalContext)
        }

        if let clientContext = self.evaluationContext {
            context.merge(clientContext)
        }

        if let invocationContext {
            context.merge(invocationContext)
        }

        return context
    }
}
