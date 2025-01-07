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
import Testing

@Suite("OpenFeatureProviderMetadata")
struct OpenFeatureProviderMetadataTests {
    @Test("subscript")
    func subscript_access() {
        var metadata = OpenFeatureProviderMetadata(name: "test-provider", values: [:])

        metadata["foo"] = "bar"

        #expect(metadata["foo"] == "bar")
    }
}
