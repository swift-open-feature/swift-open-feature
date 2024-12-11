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

public enum OpenFeatureSystem: Sendable {
    public static var provider: any OpenFeatureProvider {
        storage.provider
    }

    public static func client() -> OpenFeatureClient {
        OpenFeatureClient(provider: provider)
    }

    private static let storage = Storage()

    public static func bootstrap(_ provider: any OpenFeatureProvider) {
        storage.bootstrap(provider)
    }

    package static func bootstrapInternal(_ provider: (any OpenFeatureProvider)?) {
        storage.bootstrapInternal(provider)
    }

    private final class Storage: @unchecked Sendable {
        private var _provider: any OpenFeatureProvider = OpenFeatureNoOpProvider()
        private var _isInitialized = false
        private let lock = ReadWriteLock()

        func bootstrap(_ provider: any OpenFeatureProvider) {
            lock.withWriterLock {
                precondition(!_isInitialized, "OpenFeatureSystem can only be initialized once per process.")
                _provider = provider
                _isInitialized = true
            }
        }

        func bootstrapInternal(_ provider: (any OpenFeatureProvider)?) {
            lock.withWriterLock {
                _provider = provider ?? OpenFeatureNoOpProvider()
                _isInitialized = true
            }
        }

        var provider: any OpenFeatureProvider {
            lock.withReaderLock { _provider }
        }
    }
}
