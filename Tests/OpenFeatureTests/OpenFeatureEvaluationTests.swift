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

@Suite("OpenFeatureEvaluation")
struct OpenFeatureEvaluationTests {
    @Test("from resolution")
    func initFromResolution() async throws {
        let resolution = OpenFeatureResolution(
            value: 42,
            error: OpenFeatureResolutionError(code: .flagNotFound, message: "test"),
            reason: .error,
            variant: "default",
            flagMetadata: ["foo": .string("bar")]
        )

        let evaluation = OpenFeatureEvaluation(flag: "flag", resolution: resolution)
        let expectedEvaluation = OpenFeatureEvaluation(
            flag: "flag",
            resolution: OpenFeatureResolution(
                value: 42,
                error: OpenFeatureResolutionError(code: .flagNotFound, message: "test"),
                reason: .error,
                variant: "default",
                flagMetadata: ["foo": .string("bar")]
            )
        )

        #expect(evaluation == expectedEvaluation)
    }
}
