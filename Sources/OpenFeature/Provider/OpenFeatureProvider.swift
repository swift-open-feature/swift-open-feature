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

    func resolution<Value: OpenFeatureValue>(
        of flag: String,
        defaultValue: Value,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Value>
}

extension OpenFeatureProvider {
    public var hooks: [any OpenFeatureHook] { [] }
}
