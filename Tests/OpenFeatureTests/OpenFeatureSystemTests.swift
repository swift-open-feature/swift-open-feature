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

        OpenFeatureSystem.bootstrapInternal(OpenFeatureProviderStub())

        let providerAfterBootstrap = OpenFeatureSystem.provider

        #expect(providerAfterBootstrap is OpenFeatureProviderStub)
    }
}

// MARK: - Helpers

struct OpenFeatureProviderStub: OpenFeatureProvider {
    let metadata = OpenFeatureProviderMetadata(name: "stub")

    func run() async throws {
        try await gracefulShutdown()
    }

    func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        OpenFeatureResolution(value: defaultValue)
    }
}
