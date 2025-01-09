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

@Suite("OpenFeatureCliet")
struct OpenFeatureClientTests {
    @Suite("Bool")
    struct BoolTests {
        @Test("value", arguments: [true, false])
        func value(_ defaultValue: Bool) async {
            let provider = OpenFeatureDefaultValueProvider()
            let client = OpenFeatureClient(provider: provider)

            let value = await client.value(
                for: "flag",
                defaultingTo: defaultValue,
                context: OpenFeatureEvaluationContext(targetingKey: "targeting", fields: ["foo": .string("bar")]),
                options: OpenFeatureEvaluationOptions()
            )

            #expect(value == defaultValue)
        }

        @Test("evaluation", arguments: [true, false])
        func evaluation(_ defaultValue: Bool) async {
            let provider = OpenFeatureDefaultValueProvider()
            let client = OpenFeatureClient(provider: provider)

            let evaluation = await client.evaluation(
                of: "flag",
                defaultingTo: defaultValue,
                context: OpenFeatureEvaluationContext(targetingKey: "targeting", fields: ["foo": .string("bar")]),
                options: OpenFeatureEvaluationOptions()
            )

            #expect(evaluation == OpenFeatureEvaluation(flag: "flag", value: defaultValue))
        }
    }
}
