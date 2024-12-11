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

public protocol OpenFeatureHook: Sendable {
    func beforeEvaluation(context: inout OpenFeatureHookContext, hints: OpenFeatureHookHints) throws

    func afterSuccessfulEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: OpenFeatureHookHints
    ) throws

    func onError(context: OpenFeatureHookContext, error: Error, hints: OpenFeatureHookHints)

    func afterEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: OpenFeatureHookHints
    )
}

extension OpenFeatureHook {
    public func beforeEvaluation(context: inout OpenFeatureHookContext, hints: OpenFeatureHookHints) throws {}

    public func afterSuccessfulEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: [String: OpenFeatureFieldValue]
    ) throws {}

    public func onError(context: OpenFeatureHookContext, error: Error, hints: OpenFeatureHookHints) {}

    public func afterEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: OpenFeatureHookHints
    ) {}
}
