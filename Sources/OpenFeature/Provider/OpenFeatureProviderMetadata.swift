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

public struct OpenFeatureProviderMetadata: Hashable, Sendable {
    public let name: String
    private var values: [String: String]

    public init(name: String, values: [String: String] = [:]) {
        self.name = name
        self.values = values
    }

    public subscript(key: String) -> String? {
        get {
            values[key]
        }
        set {
            values[key] = newValue
        }
    }
}
