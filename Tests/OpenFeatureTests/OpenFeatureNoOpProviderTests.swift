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

import Logging
import OpenFeature
import ServiceLifecycle
import Testing

@Suite("OpenFeatureNoOpProvider")
struct OpenFeatureNoOpProviderTests {
    @Test("Stops on graceful shutdown")
    func gracefulShutdown() async throws {
        let provider = OpenFeatureNoOpProvider()
        var logger = Logger(label: #function)
        logger.logLevel = .trace

        let (shutdownStream, shutdownContinuation) = AsyncStream<Void>.makeStream()
        struct ShutdownService: Service, CustomStringConvertible {
            let description = "ShutdownTrigger"
            let stream: AsyncStream<Void>
            let continuation: AsyncStream<Void>.Continuation

            init(stream: AsyncStream<Void>, continuation: AsyncStream<Void>.Continuation) {
                self.stream = stream
                self.continuation = continuation
            }

            func run() async throws {
                continuation.yield()
                for await _ in stream.cancelOnGracefulShutdown() {}
            }
        }

        let serviceGroup = ServiceGroup(
            services: [provider, ShutdownService(stream: shutdownStream, continuation: shutdownContinuation)],
            logger: logger
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await serviceGroup.run()
            }

            group.addTask {
                var iterator = shutdownStream.makeAsyncIterator()
                await iterator.next()
                await serviceGroup.triggerGracefulShutdown()
            }

            try await group.waitForAll()
        }
    }

    @Suite("Resolution")
    struct ResolutionTests {
        let provider: any OpenFeatureProvider

        init() {
            provider = OpenFeatureNoOpProvider()
        }

        @Test("Bool uses default", arguments: [true, false])
        func bool(_ value: Bool) async {
            let resolution = await provider.resolution(of: "flag", defaultValue: value, context: nil)

            #expect(resolution == .fromNoOpProvider(value: value))
        }

        @Test("String uses default", arguments: ["foo", "bar"])
        func string(_ value: String) async {
            let resolution = await provider.resolution(of: "flag", defaultValue: value, context: nil)

            #expect(resolution == .fromNoOpProvider(value: value))
        }
    }
}

extension OpenFeatureResolution {
    fileprivate static func fromNoOpProvider(value: Value) -> OpenFeatureResolution {
        OpenFeatureResolution(
            value: value,
            reason: OpenFeatureNoOpProvider.noOpReason
        )
    }
}
