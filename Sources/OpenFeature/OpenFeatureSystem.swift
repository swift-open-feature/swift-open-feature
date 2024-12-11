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

    public static var hooks: [any OpenFeatureHook] {
        storage.hooks.withLock(\.self)
    }

    public static func addHooks(_ hooks: [any OpenFeatureHook]) {
        storage.hooks.withLock { $0 += hooks }
    }

    public static func client(
        evaluationContext: OpenFeatureEvaluationContext? = nil,
        hooks: [any OpenFeatureHook] = []
    ) -> OpenFeatureClient {
        OpenFeatureClient(
            provider: { provider },
            evaluationContext: evaluationContext,
            hooks: hooks,
            globalEvaluationContext: { self.evaluationContext },
            globalHooks: { self.hooks }
        )
    }

    package static func removeHooks() {
        storage.hooks.withLock { $0.removeAll() }
    }

    private static let storage = Storage.instance

    final class Storage: Sendable {
        static let instance = Storage()

        let provider = Mutex<any OpenFeatureProvider>(OpenFeatureNoOpProvider())
        let evaluationContext = Mutex<OpenFeatureEvaluationContext?>(nil)
        let hooks = Mutex<[any OpenFeatureHook]>([])

        private init() {}
    }
}
