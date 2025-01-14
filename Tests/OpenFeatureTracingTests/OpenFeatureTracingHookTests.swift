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
import OpenFeatureTracing
import Testing
import Tracing

@testable import Instrumentation

@Suite("OpenFeatureTracingHook", .serialized)
final class OpenFeatureTracingHookTests {
    deinit {
        InstrumentationSystem.bootstrapInternal(nil)
    }

    @Test("No-op without active span")
    func noOpWithoutActiveSpan() async throws {
        let hook = OpenFeatureTracingHook()
        let provider = OpenFeatureStaticProvider(boolResolution: OpenFeatureResolution(value: true))
        let client = OpenFeatureClient(provider: { provider }, hooks: [hook])

        let evaluation = await client.evaluation(of: "flag", defaultingTo: true)

        #expect(evaluation.value == true)
        #expect(evaluation.error == nil)
    }

    @Test("Adds span event without variant")
    func withoutVariant() async throws {
        let span = try await span(evaluating: OpenFeatureResolution(value: true))
        let event = try #require(span.events.first)

        #expect(event.name == "feature_flag")
        #expect(
            event.attributes == [
                "feature_flag.key": "flag",
                "feature_flag.provider_name": "static",
            ]
        )
    }

    @Test("Adds span event with variant")
    func withVariant() async throws {
        let span = try await span(evaluating: OpenFeatureResolution(value: true, variant: "a"))
        let event = try #require(span.events.first)

        #expect(event.name == "feature_flag")
        #expect(
            event.attributes == [
                "feature_flag.key": "flag",
                "feature_flag.variant": "a",
                "feature_flag.provider_name": "static",
            ]
        )
    }

    @Test("No-op error without active span")
    func noOpErrorWithoutActiveSpan() async throws {
        let hook = OpenFeatureTracingHook()
        let resolutionError = OpenFeatureResolutionError(code: .flagNotFound, message: #"Flag "flag" not found."#)
        let resolution = OpenFeatureResolution(value: true, error: resolutionError)
        let provider = OpenFeatureStaticProvider(boolResolution: resolution)
        let client = OpenFeatureClient(provider: { provider }, hooks: [hook])

        let evaluation = await client.evaluation(of: "flag", defaultingTo: true)

        #expect(evaluation.value == true)
        #expect(evaluation.error == resolutionError)
    }

    @Test("Records error")
    func recordsError() async throws {
        let resolutionError = OpenFeatureResolutionError(code: .flagNotFound, message: #"Flag "flag" not found."#)
        let span = try await span(evaluating: OpenFeatureResolution(value: true, error: resolutionError))
        let (error, attributes) = try #require(span.errors.first)

        #expect(error as? OpenFeatureResolutionError == resolutionError)
        #expect(
            attributes == [
                "feature_flag.key": "flag",
                "feature_flag.provider_name": "static",
            ]
        )
        #expect(span.status == nil)
    }

    @Test("Sets span status on error")
    func setsSpanStatusOnError() async throws {
        let resolutionError = OpenFeatureResolutionError(code: .flagNotFound, message: #"Flag "flag" not found."#)
        let span = try await span(
            evaluating: OpenFeatureResolution(value: true, error: resolutionError),
            hook: OpenFeatureTracingHook(setSpanStatusOnError: true)
        )
        let (error, attributes) = try #require(span.errors.first)

        #expect(error as? OpenFeatureResolutionError == resolutionError)
        #expect(
            attributes == [
                "feature_flag.key": "flag",
                "feature_flag.provider_name": "static",
            ]
        )
        #expect(span.status == SpanStatus(code: .error, message: #"Error evaluating flag "flag" of type "Bool"."#))
    }

    private func span(
        evaluating resolution: OpenFeatureResolution<Bool>,
        hook: OpenFeatureTracingHook = OpenFeatureTracingHook()
    ) async throws -> SingleSpanTracer.Span {
        let tracer = SingleSpanTracer()
        InstrumentationSystem.bootstrapInternal(tracer)
        let provider = OpenFeatureStaticProvider(boolResolution: resolution, hooks: [hook])
        let client = OpenFeatureClient(provider: { provider })

        await withSpan("test") { _ in
            _ = await client.value(for: "flag", defaultingTo: false)
        }

        return try #require(tracer.span)
    }
}
