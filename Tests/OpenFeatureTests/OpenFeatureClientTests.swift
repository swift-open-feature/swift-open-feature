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

@Suite("OpenFeatureCliet")
struct OpenFeatureClientTests {
    @Suite("Bool")
    struct BoolTests {
        @Test("value", arguments: [true, false])
        func value(_ defaultValue: Bool) async {
            let provider = OpenFeatureDefaultValueProvider()
            let client = OpenFeatureClient(provider: { provider })

            let value = await client.value(for: "flag", defaultingTo: defaultValue)

            #expect(value == defaultValue)
        }

        @Test("evaluation", arguments: [true, false])
        func evaluation(_ defaultValue: Bool) async {
            let provider = OpenFeatureDefaultValueProvider()
            let client = OpenFeatureClient(provider: { provider })

            let evaluation = await client.evaluation(of: "flag", defaultingTo: defaultValue)

            #expect(evaluation == OpenFeatureEvaluation(flag: "flag", value: defaultValue))
        }
    }

    @Suite("Evaluation Context Merging")
    struct EvaluationContextMergingTests {
        @Test("Starts with global")
        func globalContextOnly() async throws {
            let globalContext = OpenFeatureEvaluationContext(targetingKey: "global", fields: ["global": 42])
            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider }, globalEvaluationContext: { globalContext })

            #expect(await client.value(for: "flag", defaultingTo: true) == true)

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "global")
            #expect(request.context?.fields["global"]?.intValue == 42)
        }

        @Test("Task-local overrides global")
        func taskLocalOverridesGlobal() async throws {
            let globalContext = OpenFeatureEvaluationContext(
                targetingKey: "global",
                fields: ["global": 42, "shared": "global"]
            )
            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider }, globalEvaluationContext: { globalContext })

            let taskLocalContext = OpenFeatureEvaluationContext(
                targetingKey: "task-local",
                fields: ["task-local": 42, "shared": "task-local"]
            )

            await OpenFeatureEvaluationContext.$current.withValue(taskLocalContext) {
                #expect(await client.value(for: "flag", defaultingTo: true) == true)
            }

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "task-local")
            #expect(request.context?.fields["global"]?.intValue == 42)
            #expect(request.context?.fields["task-local"]?.intValue == 42)
            #expect(request.context?.fields["shared"]?.stringValue == "task-local")
        }

        @Test("Client overrides task-local")
        func clientOverridesTaskLocal() async throws {
            let clientContext = OpenFeatureEvaluationContext(
                targetingKey: "client",
                fields: ["client": 42, "shared": "client"]
            )
            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider })
            await client.setEvaluationContext(clientContext)

            let taskLocalContext = OpenFeatureEvaluationContext(
                targetingKey: "task-local",
                fields: ["task-local": 42, "shared": "task-local"]
            )

            await OpenFeatureEvaluationContext.$current.withValue(taskLocalContext) {
                #expect(await client.value(for: "flag", defaultingTo: true) == true)
            }

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "client")
            #expect(request.context?.fields["client"]?.intValue == 42)
            #expect(request.context?.fields["task-local"]?.intValue == 42)
            #expect(request.context?.fields["shared"]?.stringValue == "client")
        }

        @Test("Invocation overrides client")
        func invocationOverridesClient() async throws {
            let clientContext = OpenFeatureEvaluationContext(
                targetingKey: "client",
                fields: ["client": 42, "shared": "client"]
            )
            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider })
            await client.setEvaluationContext(clientContext)

            let invocationContext = OpenFeatureEvaluationContext(
                targetingKey: "invocation",
                fields: ["invocation": 42, "shared": "invocation"]
            )

            #expect(await client.value(for: "flag", defaultingTo: true, context: invocationContext) == true)

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "invocation")
            #expect(request.context?.fields["client"]?.intValue == 42)
            #expect(request.context?.fields["invocation"]?.intValue == 42)
            #expect(request.context?.fields["shared"]?.stringValue == "invocation")
        }

        @Test("Merges all contexts")
        func mergesAllContexts() async throws {
            let globalContext = OpenFeatureEvaluationContext(fields: ["global": 42])
            let taskLocalContext = OpenFeatureEvaluationContext(targetingKey: "task-local", fields: ["task-local": 42])
            let clientContext = OpenFeatureEvaluationContext(fields: ["client": 42])
            let invocationContext = OpenFeatureEvaluationContext(fields: ["invocation": 42])

            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider }, globalEvaluationContext: { globalContext })
            await client.setEvaluationContext(clientContext)

            await OpenFeatureEvaluationContext.$current.withValue(taskLocalContext) {
                #expect(await client.value(for: "flag", defaultingTo: true, context: invocationContext) == true)
            }

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "task-local")
            #expect(request.context?.fields["global"]?.intValue == 42)
            #expect(request.context?.fields["task-local"]?.intValue == 42)
            #expect(request.context?.fields["client"]?.intValue == 42)
            #expect(request.context?.fields["invocation"]?.intValue == 42)
        }
    }
}
