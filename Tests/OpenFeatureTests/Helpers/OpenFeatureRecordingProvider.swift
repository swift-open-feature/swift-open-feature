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

actor OpenFeatureRecordingProvider: OpenFeatureProvider {
    let metadata = OpenFeatureProviderMetadata(name: "recording")
    let hooks: [any OpenFeatureHook]
    var boolResolutionRequests = [ResolutionRequest<Bool>]()

    init(hooks: [any OpenFeatureHook] = []) {
        self.hooks = hooks
    }

    func run() async throws {
        try await gracefulShutdown()
    }

    func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        let request = ResolutionRequest(flag: flag, defaultValue: defaultValue, context: context)
        boolResolutionRequests.append(request)
        return OpenFeatureResolution(value: defaultValue)
    }

    struct ResolutionRequest<Value: Sendable> {
        let flag: String
        let defaultValue: Value
        let context: OpenFeatureEvaluationContext?
    }
}
