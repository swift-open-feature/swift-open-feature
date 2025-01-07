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

import ServiceLifecycle

public struct OpenFeatureNoOpProvider: OpenFeatureProvider, CustomStringConvertible {
    public let description = "OpenFeatureNoOpProvider"
    public let metadata = OpenFeatureProviderMetadata(name: "No-op Provider")
    package static let noOpReason = OpenFeatureResolutionReason(rawValue: "No-op")

    public init() {}

    public func run() async throws {
        try await gracefulShutdown()
    }

    public func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        OpenFeatureResolution(value: defaultValue, reason: Self.noOpReason)
    }
}
