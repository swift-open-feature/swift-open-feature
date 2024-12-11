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

@Suite("OpenFeatureClient")
struct OpenFeatureClientTests {
    @Suite("Hooks")
    struct HookTests {
        @Suite("Bool")
        struct BoolHookTests {
            let client: OpenFeatureClient
            let provider: RecordingProvider

            init() {
                provider = RecordingProvider()
                client = OpenFeatureClient(provider: provider)
            }

            @Test("Adds context")
            func addsContext() async throws {
                client.addHook(StubHook(fields: ["foo": "bar"]))

                _ = await client.value(for: "flag", defaultingTo: true)

                let request = try #require(provider.boolResolutionRequests.first)
                let context = try #require(request.context)
                #expect(context.fields["foo"]?.stringValue == "bar")
            }

            @Test("Overrides ad-hoc fields")
            func hookOverridesAdHoc() async throws {
                client.addHook(StubHook(fields: ["hook": 42, "common": "hook"]))

                let adHocContext = OpenFeatureEvaluationContext(
                    fields: [
                        "adhoc": "stub",
                        "common": "ad-hoc",
                    ]
                )
                _ = await client.value(for: "flag", defaultingTo: true, context: adHocContext)

                let request = try #require(provider.boolResolutionRequests.first)
                let context = try #require(request.context)
                #expect(context.fields["hook"]?.intValue == 42)
                #expect(context.fields["common"]?.stringValue == "hook")
            }
        }

        @Suite("Bool Evaluation")
        struct BoolHookEvaluationTests {
            let client: OpenFeatureClient
            let provider: RecordingProvider

            init() {
                provider = RecordingProvider()
                client = OpenFeatureClient(provider: provider)
            }

            @Test("Adds context")
            func addsContext() async throws {
                client.addHook(StubHook(fields: ["foo": "bar"]))

                _ = await client.evaluation(of: "flag", defaultingTo: true)

                let request = try #require(provider.boolResolutionRequests.first)
                let context = try #require(request.context)
                #expect(context.fields["foo"]?.stringValue == "bar")
            }

            @Test("Overrides ad-hoc fields")
            func hookOverridesAdHoc() async throws {
                client.addHook(StubHook(fields: ["hook": 42, "common": "hook"]))

                let adHocContext = OpenFeatureEvaluationContext(
                    fields: [
                        "adhoc": "stub",
                        "common": "ad-hoc",
                    ]
                )
                _ = await client.evaluation(of: "flag", defaultingTo: true, context: adHocContext)

                let request = try #require(provider.boolResolutionRequests.first)
                let context = try #require(request.context)
                #expect(context.fields["hook"]?.intValue == 42)
                #expect(context.fields["common"]?.stringValue == "hook")
            }
        }
    }
}

final class RecordingProvider: OpenFeatureProvider {
    var boolResolutionRequests: [ResolutionRequest<Bool>] { _boolResolutionRequests.withValue(\.self) }

    private let _boolResolutionRequests = LockedValueBox([ResolutionRequest<Bool>]())

    func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        let resolution = OpenFeatureResolution<Bool>(value: defaultValue)
        _boolResolutionRequests.withValue { $0.append(ResolutionRequest(resolution: resolution, context: context)) }
        return resolution
    }

    func resolve(
        _ flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> Bool {
        await resolution(of: flag, defaultValue: defaultValue, context: context).value
    }

    func run() async throws {
        Issue.record("Recording provider is not intended to be ran as a service.")
    }

    struct ResolutionRequest<Value: Sendable & Equatable>: Sendable {
        let resolution: OpenFeatureResolution<Value>
        let context: OpenFeatureEvaluationContext?
    }
}

extension OpenFeatureFieldValue {
    fileprivate var stringValue: String? {
        guard case .string(let string) = self else { return nil }
        return string
    }

    fileprivate var intValue: Int? {
        guard case .int(let int) = self else { return nil }
        return int
    }
}

private struct StubHook: OpenFeatureHook {
    let fields: [String: OpenFeatureFieldValue]

    func beforeEvaluation(
        of flag: String,
        defaultValue: Bool,
        context: inout OpenFeatureEvaluationContext,
        hints: [String: OpenFeatureFieldValue]
    ) {
        context.fields.merge(fields, uniquingKeysWith: { $1 })
    }
}
