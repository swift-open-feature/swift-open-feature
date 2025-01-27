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

import ServiceLifecycle

public protocol OpenFeatureProvider: Service {
    var metadata: OpenFeatureProviderMetadata { get }
    var hooks: [any OpenFeatureHook] { get }

    func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool>
}

extension OpenFeatureProvider {
    public var hooks: [any OpenFeatureHook] { [] }
}
