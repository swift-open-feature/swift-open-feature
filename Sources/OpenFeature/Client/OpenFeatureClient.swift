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
    private var evaluationContext: OpenFeatureEvaluationContext?
    private var hooks: [any OpenFeatureHook]
    private let globalEvaluationContext: () -> OpenFeatureEvaluationContext?
    private let globalHooks: () -> [any OpenFeatureHook]

    public func value(
        for flag: String,
        defaultingTo defaultValue: Bool,
        context: OpenFeatureEvaluationContext? = nil,
        hooks: [any OpenFeatureHook] = [],
        hookHints: [String: OpenFeatureFieldValue] = [:]
    ) async -> Bool {
        await evaluation(
            of: flag,
            defaultingTo: defaultValue,
            context: context,
            hooks: hooks,
            hookHints: hookHints
        ).value
    }

    public func value(
        for flag: String,
        defaultingTo defaultValue: String,
        context: OpenFeatureEvaluationContext? = nil,
        hooks: [any OpenFeatureHook] = [],
        hookHints: [String: OpenFeatureFieldValue] = [:]
    ) async -> String {
        await evaluation(
            of: flag,
            defaultingTo: defaultValue,
            context: context,
            hooks: hooks,
            hookHints: hookHints
        ).value
    }

    public func evaluation(
        of flag: String,
        defaultingTo defaultValue: Bool,
        context: OpenFeatureEvaluationContext? = nil,
        hooks: [any OpenFeatureHook] = [],
        hookHints: [String: OpenFeatureFieldValue] = [:]
    ) async -> OpenFeatureEvaluation<Bool> {
        await evaluation(
            of: flag,
            defaultingTo: defaultValue,
            context: context,
            hooks: hooks,
            hookHints: hookHints,
            performResolution: { provider, flag, defaultValue, context in
                await provider.resolution(of: flag, defaultValue: defaultValue, context: context)
            }
        )
    }

    public func evaluation(
        of flag: String,
        defaultingTo defaultValue: String,
        context: OpenFeatureEvaluationContext? = nil,
        hooks: [any OpenFeatureHook] = [],
        hookHints: [String: OpenFeatureFieldValue] = [:]
    ) async -> OpenFeatureEvaluation<String> {
        await evaluation(
            of: flag,
            defaultingTo: defaultValue,
            context: context,
            hooks: hooks,
            hookHints: hookHints,
            performResolution: { provider, flag, defaultValue, context in
                await provider.resolution(of: flag, defaultValue: defaultValue, context: context)
            }
        )
    }

    public func setEvaluationContext(_ evaluationContext: OpenFeatureEvaluationContext?) {
        self.evaluationContext = evaluationContext
    }

    public func addHooks(_ hooks: [any OpenFeatureHook]) {
        self.hooks += hooks
    }

    package init(
        provider: @escaping () -> any OpenFeatureProvider,
        evaluationContext: OpenFeatureEvaluationContext? = nil,
        hooks: [any OpenFeatureHook] = [],
        globalEvaluationContext: @escaping () -> OpenFeatureEvaluationContext? = { nil },
        globalHooks: @escaping () -> [any OpenFeatureHook] = { [] }
    ) {
        self.evaluationContext = evaluationContext
        self.provider = provider
        self.hooks = hooks
        self.globalEvaluationContext = globalEvaluationContext
        self.globalHooks = globalHooks
    }

    private func evaluation<Value>(
        of flag: String,
        defaultingTo defaultValue: Value,
        context: OpenFeatureEvaluationContext?,
        hooks: [any OpenFeatureHook],
        hookHints: [String: OpenFeatureFieldValue],
        performResolution: (
            _ provider: any OpenFeatureProvider,
            _ flag: String,
            _ defaultValue: Value,
            _ context: OpenFeatureEvaluationContext
        ) async -> OpenFeatureResolution<Value>
    ) async -> OpenFeatureEvaluation<Value> {
        let provider = provider()
        let globalHooks = globalHooks()
        let context = mergedEvaluationContext(invocationContext: context)
        let beforeHooks = mergedBeforeHooks(
            globalHooks: globalHooks,
            invocationHooks: hooks,
            providerHooks: provider.hooks
        )
        let afterHooks = mergedAfterHooks(
            providerHooks: provider.hooks,
            invocationHooks: hooks,
            globalHooks: globalHooks
        )
        let errorHooks = afterHooks
        var hookContext = OpenFeatureHookContext(
            flag: flag,
            defaultValue: defaultValue,
            evaluationContext: context,
            providerMetadata: provider.metadata
        )

        for hook in beforeHooks {
            do {
                try hook.beforeEvaluation(
                    context: &hookContext,
                    hints: hookHints
                )
            } catch {
                return failedEvaluation(
                    error: error,
                    flag: flag,
                    defaultValue: defaultValue,
                    hookContext: hookContext,
                    hookHints: hookHints,
                    errorHooks: errorHooks,
                    afterHooks: afterHooks
                )
            }
        }

        let resolution = await performResolution(
            provider,
            flag,
            defaultValue,
            hookContext.evaluationContext
        )
        let evaluation = OpenFeatureEvaluation(flag: flag, resolution: resolution)

        if let error = resolution.error {
            for hook in errorHooks {
                hook.onError(context: hookContext, error: error, hints: hookHints)
            }
        } else {
            for hook in afterHooks {
                do {
                    try hook.afterSuccessfulEvaluation(
                        context: hookContext,
                        evaluation: evaluation,
                        hints: hookHints
                    )
                } catch {
                    return failedEvaluation(
                        error: error,
                        flag: flag,
                        defaultValue: defaultValue,
                        hookContext: hookContext,
                        hookHints: hookHints,
                        errorHooks: errorHooks,
                        afterHooks: afterHooks
                    )
                }
            }
        }

        for hook in afterHooks {
            hook.afterEvaluation(context: hookContext, evaluation: evaluation, hints: hookHints)
        }

        return evaluation
    }

    private func mergedEvaluationContext(
        invocationContext: OpenFeatureEvaluationContext?
    ) -> OpenFeatureEvaluationContext {
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

    private func mergedBeforeHooks(
        globalHooks: [any OpenFeatureHook],
        invocationHooks: [any OpenFeatureHook],
        providerHooks: [any OpenFeatureHook]
    ) -> [any OpenFeatureHook] {
        var hooks = globalHooks
        hooks += self.hooks
        hooks += invocationHooks
        hooks += providerHooks
        return hooks
    }

    private func mergedAfterHooks(
        providerHooks: [any OpenFeatureHook],
        invocationHooks: [any OpenFeatureHook],
        globalHooks: [any OpenFeatureHook]
    ) -> [any OpenFeatureHook] {
        var hooks = providerHooks
        hooks += invocationHooks
        hooks += self.hooks
        hooks += globalHooks
        return hooks
    }

    private func failedEvaluation<Value: OpenFeatureValue>(
        error: any Error,
        flag: String,
        defaultValue: Value,
        hookContext: OpenFeatureHookContext,
        hookHints: OpenFeatureHookHints,
        errorHooks: [any OpenFeatureHook],
        afterHooks: [any OpenFeatureHook]
    ) -> OpenFeatureEvaluation<Value> {
        for hook in errorHooks {
            hook.onError(context: hookContext, error: error, hints: hookHints)
        }

        let error: OpenFeatureResolutionError = {
            guard let error = error as? OpenFeatureResolutionError else {
                return OpenFeatureResolutionError(code: .general, message: "\(error)")
            }
            return error
        }()

        let evaluation = OpenFeatureEvaluation(
            flag: flag,
            value: defaultValue,
            error: error,
            reason: .error
        )

        for hook in afterHooks {
            hook.afterEvaluation(context: hookContext, evaluation: evaluation, hints: hookHints)
        }

        return evaluation
    }
}
