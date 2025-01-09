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

        OpenFeatureSystem.bootstrapInternal(OpenFeatureDefaultValueProvider())

        let providerAfterBootstrap = OpenFeatureSystem.provider

        #expect(providerAfterBootstrap is OpenFeatureDefaultValueProvider)
    }

    @Test("Client uses bootstrapped provider")
    func clientUsesBootstrappedProvider() async throws {
        let provider = OpenFeatureDefaultValueProvider()
        OpenFeatureSystem.bootstrapInternal(provider)

        let client = OpenFeatureSystem.client()

        #expect(client.provider.metadata.name == provider.metadata.name)
    }
}
