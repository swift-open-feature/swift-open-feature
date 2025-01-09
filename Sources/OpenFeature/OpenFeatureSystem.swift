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

import Synchronization

public enum OpenFeatureSystem: Sendable {
    public static var provider: any OpenFeatureProvider {
        storage.provider.withLock(\.self)
    }

    public static func setProvider(_ provider: some OpenFeatureProvider) {
        storage.provider.withLock { $0 = provider }
    }

    public static var evaluationContext: OpenFeatureEvaluationContext? {
        storage.evaluationContext.withLock(\.self)
    }

    public static func setEvaluationContext(_ evaluationContext: OpenFeatureEvaluationContext?) {
        storage.evaluationContext.withLock { $0 = evaluationContext }
    }

    public static func client(evaluationContext: OpenFeatureEvaluationContext? = nil) -> OpenFeatureClient {
        OpenFeatureClient(
            provider: { provider },
            globalEvaluationContext: { evaluationContext },
            evaluationContext: evaluationContext
        )
    }

    private static let storage = Storage.instance

    final class Storage: Sendable {
        static let instance = Storage()

        let provider = Mutex<any OpenFeatureProvider>(OpenFeatureNoOpProvider())
        let evaluationContext = Mutex<OpenFeatureEvaluationContext?>(nil)

        private init() {}
    }
}
