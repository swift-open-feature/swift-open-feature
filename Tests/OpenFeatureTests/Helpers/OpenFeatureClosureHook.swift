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

import OpenFeature

struct OpenFeatureClosureHook: OpenFeatureHook {
    typealias BeforeEvaluation = @Sendable (
        _ context: inout OpenFeatureHookContext,
        _ hints: OpenFeatureHookHints
    ) throws -> Void

    typealias AfterSuccessfulEvaluation = @Sendable (
        _ context: OpenFeatureHookContext,
        _ evaluation: AnyOpenFeatureEvaluation,
        _ hints: OpenFeatureHookHints
    ) throws -> Void

    typealias OnError = @Sendable (
        _ context: OpenFeatureHookContext,
        _ error: any Error,
        _ hints: OpenFeatureHookHints
    ) -> Void

    typealias AfterEvaluation = @Sendable (
        _ context: OpenFeatureHookContext,
        _ evaluation: AnyOpenFeatureEvaluation,
        _ hints: OpenFeatureHookHints
    ) -> Void

    var beforeEvaluation: BeforeEvaluation?
    var afterSuccessfulEvaluation: AfterSuccessfulEvaluation?
    var onError: OnError?
    var afterEvaluation: AfterEvaluation?

    func beforeEvaluation(
        context: inout OpenFeatureHookContext,
        hints: [String: OpenFeatureFieldValue]
    ) throws {
        try beforeEvaluation?(&context, hints)
    }

    func afterSuccessfulEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: [String: OpenFeatureFieldValue]
    ) throws {
        try afterSuccessfulEvaluation?(context, evaluation.eraseToAnyEvaluation(), hints)
    }

    func onError(context: OpenFeatureHookContext, error: any Error, hints: OpenFeatureHookHints) {
        onError?(context, error, hints)
    }

    func afterEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: OpenFeatureHookHints
    ) {
        afterEvaluation?(context, evaluation.eraseToAnyEvaluation(), hints)
    }
}

struct AnyOpenFeatureEvaluation {
    let flag: String
    let value: any OpenFeatureValue
    let error: OpenFeatureResolutionError?
    let reason: OpenFeatureResolutionReason?
    let variant: String?
    let flagMetadata: [String: OpenFeatureFlagMetadataValue]

    fileprivate init(_ evaluation: OpenFeatureEvaluation<some OpenFeatureValue>) {
        self.flag = evaluation.flag
        self.value = evaluation.value
        self.error = evaluation.error
        self.reason = evaluation.reason
        self.variant = evaluation.variant
        self.flagMetadata = evaluation.flagMetadata
    }
}

extension OpenFeatureEvaluation {
    func eraseToAnyEvaluation() -> AnyOpenFeatureEvaluation {
        AnyOpenFeatureEvaluation(self)
    }
}
