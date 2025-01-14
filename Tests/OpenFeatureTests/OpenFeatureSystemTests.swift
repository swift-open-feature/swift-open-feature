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
import OpenFeatureTestSupport
import ServiceLifecycle
import Testing

@Suite("OpenFeatureSystem", .serialized)
final class OpenFeatureSystemTests {
    deinit {
        OpenFeatureSystem.setProvider(OpenFeatureNoOpProvider())
        OpenFeatureSystem.setEvaluationContext(nil)
        OpenFeatureSystem.removeHooks()
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

    @Test("Add hooks")
    func addHooks() async throws {
        #expect(OpenFeatureSystem.hooks.isEmpty)

        let targetingKey = "I'm hooked! 😍"
        let hook = OpenFeatureClosureHook(beforeEvaluation: { context, _ in
            context.evaluationContext.targetingKey = targetingKey
        })
        OpenFeatureSystem.addHooks([hook])

        let provider = OpenFeatureRecordingProvider()
        OpenFeatureSystem.setProvider(provider)
        let client = OpenFeatureSystem.client()
        #expect(await client.value(for: "key", defaultingTo: true) == true)
        #expect(await provider.boolResolutionRequests.count == 1)

        let resolutionRequest = try #require(await provider.boolResolutionRequests.first)
        #expect(resolutionRequest.context?.targetingKey == targetingKey)
    }
}
