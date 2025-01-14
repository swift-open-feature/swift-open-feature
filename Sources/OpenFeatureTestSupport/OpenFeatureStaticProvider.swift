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

package struct OpenFeatureStaticProvider: OpenFeatureProvider {
    package let metadata = OpenFeatureProviderMetadata(name: "static")
    package let hooks: [any OpenFeatureHook]

    private let boolResolution: OpenFeatureResolution<Bool>

    package init(boolResolution: OpenFeatureResolution<Bool>, hooks: [any OpenFeatureHook] = []) {
        self.boolResolution = boolResolution
        self.hooks = hooks
    }

    package func run() async throws {
        try await gracefulShutdown()
    }

    package func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        boolResolution
    }
}
