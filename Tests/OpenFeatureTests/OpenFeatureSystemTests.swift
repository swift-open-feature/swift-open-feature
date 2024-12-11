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
import Testing

@Suite("OpenFeatureSystem")
final class OpenFeatureSystemTests {
    deinit {
        OpenFeatureSystem.bootstrapInternal(nil)
    }

    @Test("Returns bootstrapped provider")
    func bootstrappedProvider() async throws {
        let providerBeforeBootstrap = OpenFeatureSystem.provider

        #expect(providerBeforeBootstrap is OpenFeatureNoOpProvider)

        OpenFeatureSystem.bootstrapInternal(OpenFeatureProviderA())

        let providerAfterBootstrap = OpenFeatureSystem.provider

        #expect(providerAfterBootstrap is OpenFeatureProviderA)
    }
}

// MARK: - Helpers

struct OpenFeatureProviderA: OpenFeatureProvider {
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    public init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    public func run() async throws {
        for await _ in stream.cancelOnGracefulShutdown() {}
    }

    func resolve(_ flag: String, defaultValue: Bool, context: OpenFeatureEvaluationContext?) async -> Bool {
        defaultValue
    }

    func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        OpenFeatureResolution(value: defaultValue, error: nil, reason: nil, variant: nil, flagMetadata: [:])
    }
}
