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
import ServiceLifecycle

package actor OpenFeatureRecordingProvider: OpenFeatureProvider {
    package let metadata = OpenFeatureProviderMetadata(name: "recording")
    package let hooks: [any OpenFeatureHook]

    package var boolResolutionRequests = [ResolutionRequest<Bool>]()
    package var stringResolutionRequests = [ResolutionRequest<String>]()

    package init(hooks: [any OpenFeatureHook] = []) {
        self.hooks = hooks
    }

    package func run() async throws {
        try await gracefulShutdown()
    }

    package func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        let request = ResolutionRequest(
            flag: flag,
            defaultValue: defaultValue,
            context: context
        )
        boolResolutionRequests.append(request)
        return OpenFeatureResolution(value: defaultValue)
    }

    package func resolution(
        of flag: String,
        defaultValue: String,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<String> {
        let request = ResolutionRequest(
            flag: flag,
            defaultValue: defaultValue,
            context: context
        )
        stringResolutionRequests.append(request)
        return OpenFeatureResolution(value: defaultValue)
    }

    package struct ResolutionRequest<Value: Sendable> {
        package let flag: String
        package let defaultValue: Value
        package let context: OpenFeatureEvaluationContext?
    }
}
