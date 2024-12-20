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
    func resolution(
        of flag: String,
        defaultValue: Bool,
        context: OpenFeatureEvaluationContext?
    ) async -> OpenFeatureResolution<Bool>

    func resolve(_ flag: String, defaultValue: Bool, context: OpenFeatureEvaluationContext?) async -> Bool
}
