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

@Suite("OpenFeatureSystem", .serialized)
final class OpenFeatureSystemTests {
    deinit {
        OpenFeatureSystem.setProvider(OpenFeatureNoOpProvider())
    }

    @Test("Returns global provider")
    func globalProvider() async throws {
        let providerBeforeBootstrap = OpenFeatureSystem.provider

        #expect(providerBeforeBootstrap is OpenFeatureNoOpProvider)

        OpenFeatureSystem.setProvider(OpenFeatureDefaultValueProvider())

        let providerAfterBootstrap = OpenFeatureSystem.provider

        #expect(providerAfterBootstrap is OpenFeatureDefaultValueProvider)
    }

    @Test("Update evaluation context")
    func updateEvaluationContext() async throws {
        #expect(OpenFeatureSystem.evaluationContext == nil)

        let context = OpenFeatureEvaluationContext(targetingKey: "global", fields: ["global": 42])
        OpenFeatureSystem.setEvaluationContext(context)

        #expect(OpenFeatureSystem.evaluationContext?.targetingKey == "global")
        #expect(OpenFeatureSystem.evaluationContext?.fields["global"]?.intValue == 42)
    }

    @Test("Client uses global provider")
    func clientWithGlobalProvider() async throws {
        let client = OpenFeatureSystem.client()

        // the default provider (no-op) always returns the given default value
        #expect(await client.value(for: "key", defaultingTo: false) == false)

        let provider = OpenFeatureStaticProvider(boolResolution: OpenFeatureResolution(value: true))
        OpenFeatureSystem.setProvider(provider)

        #expect(await client.value(for: "key", defaultingTo: false) == true)
    }
}
