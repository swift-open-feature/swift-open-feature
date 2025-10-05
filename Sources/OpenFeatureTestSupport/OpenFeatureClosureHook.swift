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

package struct OpenFeatureClosureHook: OpenFeatureHook {
    package typealias BeforeEvaluation =
        @Sendable (
            _ context: inout OpenFeatureHookContext,
            _ hints: OpenFeatureHookHints
        ) throws -> Void

    package typealias AfterSuccessfulEvaluation =
        @Sendable (
            _ context: OpenFeatureHookContext,
            _ evaluation: AnyOpenFeatureEvaluation,
            _ hints: OpenFeatureHookHints
        ) throws -> Void

    package typealias OnError =
        @Sendable (
            _ context: OpenFeatureHookContext,
            _ error: any Error,
            _ hints: OpenFeatureHookHints
        ) -> Void

    package typealias AfterEvaluation =
        @Sendable (
            _ context: OpenFeatureHookContext,
            _ evaluation: AnyOpenFeatureEvaluation,
            _ hints: OpenFeatureHookHints
        ) -> Void

    package var beforeEvaluation: BeforeEvaluation?
    package var afterSuccessfulEvaluation: AfterSuccessfulEvaluation?
    package var onError: OnError?
    package var afterEvaluation: AfterEvaluation?

    package init(
        beforeEvaluation: BeforeEvaluation? = nil,
        afterSuccessfulEvaluation: AfterSuccessfulEvaluation? = nil,
        onError: OnError? = nil,
        afterEvaluation: AfterEvaluation? = nil
    ) {
        self.beforeEvaluation = beforeEvaluation
        self.afterSuccessfulEvaluation = afterSuccessfulEvaluation
        self.onError = onError
        self.afterEvaluation = afterEvaluation
    }

    package func beforeEvaluation(
        context: inout OpenFeatureHookContext,
        hints: [String: OpenFeatureFieldValue]
    ) throws {
        try beforeEvaluation?(&context, hints)
    }

    package func afterSuccessfulEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: [String: OpenFeatureFieldValue]
    ) throws {
        try afterSuccessfulEvaluation?(context, evaluation.eraseToAnyEvaluation(), hints)
    }

    package func onError(context: OpenFeatureHookContext, error: any Error, hints: OpenFeatureHookHints) {
        onError?(context, error, hints)
    }

    package func afterEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: OpenFeatureHookHints
    ) {
        afterEvaluation?(context, evaluation.eraseToAnyEvaluation(), hints)
    }
}

package struct AnyOpenFeatureEvaluation {
    package let flag: String
    package let value: any OpenFeatureValue
    package let error: OpenFeatureResolutionError?
    package let reason: OpenFeatureResolutionReason?
    package let variant: String?
    package let flagMetadata: [String: OpenFeatureFlagMetadataValue]

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
    fileprivate func eraseToAnyEvaluation() -> AnyOpenFeatureEvaluation {
        AnyOpenFeatureEvaluation(self)
    }
}
