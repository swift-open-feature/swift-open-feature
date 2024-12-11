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

public final class OpenFeatureClient: Sendable {
    private let provider: any OpenFeatureProvider
    private let hooks = LockedValueBox([any OpenFeatureHook]())

    // MARK: - Evaluation

    public func value(
        for flag: String,
        defaultingTo defaultValue: Bool,
        context: OpenFeatureEvaluationContext? = nil,
        options: OpenFeatureEvaluationOptions? = nil
    ) async -> Bool {
        var context = context ?? OpenFeatureEvaluationContext()
        hooks.withValue { hooks in
            for hook in hooks {
                hook.beforeEvaluation(of: flag, defaultValue: defaultValue, context: &context, hints: [:])
            }
        }
        return await provider.resolve(flag, defaultValue: defaultValue, context: context)
    }

    public func evaluation(
        of flag: String,
        defaultingTo defaultValue: Bool,
        context: OpenFeatureEvaluationContext? = nil,
        options: OpenFeatureEvaluationOptions? = nil
    ) async -> OpenFeatureEvaluation<Bool> {
        var context = context ?? OpenFeatureEvaluationContext()
        hooks.withValue { hooks in
            for hook in hooks {
                hook.beforeEvaluation(of: flag, defaultValue: defaultValue, context: &context, hints: [:])
            }
        }
        let resolution = await provider.resolution(of: flag, defaultValue: defaultValue, context: context)
        return OpenFeatureEvaluation(flag: flag, resolution: resolution)
    }

    // MARK: - Hooks

    public func addHook(_ hook: any OpenFeatureHook) {
        hooks.withValue { $0.append(hook) }
    }

    package init(provider: any OpenFeatureProvider) {
        self.provider = provider
    }
}
