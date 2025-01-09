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

@Suite("OpenFeatureEvaluationContext")
struct OpenFeatureEvaluationContextTests {
    @Test("Merge overrides targeting key")
    func merge() async throws {
        var context = OpenFeatureEvaluationContext(
            targetingKey: "1",
            fields: ["1": "1"]
        )

        context.merge(
            OpenFeatureEvaluationContext(
                targetingKey: "2",
                fields: ["2": "2", "shared": "2"]
            )
        )

        #expect(context.targetingKey == "2")
        #expect(context.fields["1"]?.stringValue == "1")
        #expect(context.fields["2"]?.stringValue == "2")
        #expect(context.fields["shared"]?.stringValue == "2")
    }

    @Test("Merge doesn't override targeting key with nil")
    func mergeNilTargetingKey() async throws {
        var context = OpenFeatureEvaluationContext(
            targetingKey: "1",
            fields: ["1": "1", "shared": "1"]
        )

        context.merge(
            OpenFeatureEvaluationContext(
                targetingKey: nil,
                fields: ["2": "2", "shared": "2"]
            )
        )

        #expect(context.targetingKey == "1")
        #expect(context.fields["1"]?.stringValue == "1")
        #expect(context.fields["2"]?.stringValue == "2")
        #expect(context.fields["shared"]?.stringValue == "2")
    }
}
