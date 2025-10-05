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

#if ServiceLifecycle
import ServiceLifecycle
#endif

package struct OpenFeatureStaticProvider: OpenFeatureProvider {
    package let metadata = OpenFeatureProviderMetadata(name: "static")
    package let hooks: [any OpenFeatureHook]

    private let boolResolution: OpenFeatureResolution<Bool>?
    private let stringResolution: OpenFeatureResolution<String>?
    private let intResolution: OpenFeatureResolution<Int>?
    private let doubleResolution: OpenFeatureResolution<Double>?

    package init(
        boolResolution: OpenFeatureResolution<Bool>? = nil,
        stringResolution: OpenFeatureResolution<String>? = nil,
        intResolution: OpenFeatureResolution<Int>? = nil,
        doubleResolution: OpenFeatureResolution<Double>? = nil,
        hooks: [any OpenFeatureHook] = []
    ) {
        self.boolResolution = boolResolution
        self.stringResolution = stringResolution
        self.intResolution = intResolution
        self.doubleResolution = doubleResolution
        self.hooks = hooks
    }

    package func run() async throws {
        #if ServiceLifecycle
        try await gracefulShutdown()
        #endif
    }

    package func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeature.OpenFeatureEvaluationContext?
    ) async -> OpenFeature.OpenFeatureResolution<Bool> {
        boolResolution!
    }

    package func resolution(
        of flag: String,
        defaultValue: String,
        context: OpenFeature.OpenFeatureEvaluationContext?
    ) async -> OpenFeature.OpenFeatureResolution<String> {
        stringResolution!
    }

    package func resolution(
        of flag: String,
        defaultValue: Int,
        context: OpenFeature.OpenFeatureEvaluationContext?
    ) async -> OpenFeature.OpenFeatureResolution<Int> {
        intResolution!
    }

    package func resolution(
        of flag: String,
        defaultValue: Double,
        context: OpenFeature.OpenFeatureEvaluationContext?
    ) async -> OpenFeature.OpenFeatureResolution<Double> {
        doubleResolution!
    }
}
