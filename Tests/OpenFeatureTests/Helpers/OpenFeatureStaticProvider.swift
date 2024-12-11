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

struct OpenFeatureStaticProvider: OpenFeatureProvider {
    let metadata = OpenFeatureProviderMetadata(name: "static")
    let hooks: [any OpenFeatureHook]

    private let boolResolution: OpenFeatureResolution<Bool>

    init(boolResolution: OpenFeatureResolution<Bool>, hooks: [any OpenFeatureHook] = []) {
        self.boolResolution = boolResolution
        self.hooks = hooks
    }

    func run() async throws {
        try await gracefulShutdown()
    }

    func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool> {
        boolResolution
    }
}
