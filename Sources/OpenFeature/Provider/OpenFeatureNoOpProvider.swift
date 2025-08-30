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

#if ServiceLifecycleSupport
import ServiceLifecycle
#endif

public struct OpenFeatureNoOpProvider: OpenFeatureProvider, CustomStringConvertible {
    public let description = "OpenFeatureNoOpProvider"
    public let metadata = OpenFeatureProviderMetadata(name: "No-op Provider")
    package static let noOpReason = OpenFeatureResolutionReason(rawValue: "No-op")

    public init() {}

    public func run() async throws {
        #if ServiceLifecycleSupport
        try await gracefulShutdown()
        #endif
    }

    public func resolution<Value: OpenFeatureValue>(
        of flag: String,
        defaultValue: Value,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Value> {
        OpenFeatureResolution(value: defaultValue, reason: Self.noOpReason)
    }
}
