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

public struct OpenFeatureClient {
    private let provider: any OpenFeatureProvider

    init(provider: any OpenFeatureProvider) {
        self.provider = provider
    }
}
