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
    private var resolutionRequests = [ResolutionRequest<any OpenFeatureValue>]()
    package var boolResolutionRequests: [ResolutionRequest<Bool>] {
        resolutionRequests.compactMap {
            if let boolDefaultValue = $0.defaultValue as? Bool {
                ResolutionRequest(
                    flag: $0.flag,
                    defaultValue: boolDefaultValue,
                    context: $0.context
                )
            } else {
                nil
            }
        }
    }

    package init(hooks: [any OpenFeatureHook] = []) {
        self.hooks = hooks
    }

    package func run() async throws {
        try await gracefulShutdown()
    }

    package func resolution<Value: OpenFeatureValue>(
        of flag: String,
        defaultValue: Value,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Value> {
        let request = ResolutionRequest<any OpenFeatureValue>(
            flag: flag,
            defaultValue: defaultValue,
            context: context
        )
        resolutionRequests.append(request)
        return OpenFeatureResolution(value: defaultValue)
    }

    package struct ResolutionRequest<Value: Sendable> {
        package let flag: String
        package let defaultValue: Value
        package let context: OpenFeatureEvaluationContext?

        func mapDefaultValue<NewValue>(
            transform: (Value) -> NewValue
        ) -> ResolutionRequest<NewValue> {
            ResolutionRequest<NewValue>(
                flag: flag,
                defaultValue: transform(defaultValue),
                context: context
            )
        }
    }
}
