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
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation
    package static let variant = "default-variant"

    public init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    public func run() async throws {
        for await _ in stream.cancelOnGracefulShutdown() {}
    }

    public func resolve(_ flag: String, defaultValue: Bool, context: OpenFeatureEvaluationContext?) async -> Bool {
        defaultValue
    }

    public func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        OpenFeatureResolution(
            value: defaultValue,
            reason: .default,
            variant: Self.variant
        )
    }
}
