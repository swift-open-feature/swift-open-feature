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

@Suite("OpenFeatureFieldValue")
struct OpenFeatureFieldValueTests {
    @Test("Init from bool literal")
    func boolLiteral() async throws {
        let value: OpenFeatureFieldValue = true

        guard case .bool(true) = value else {
            Issue.record("\(value)")
            return
        }
    }

    @Test("Init from string literal")
    func stringLiteral() async throws {
        let value: OpenFeatureFieldValue = "🏎️"

        guard case .string("🏎️") = value else {
            Issue.record("\(value)")
            return
        }
    }

    @Test("Init from integer literal")
    func intLiteral() async throws {
        let value: OpenFeatureFieldValue = 42

        guard case .int(42) = value else {
            Issue.record("\(value)")
            return
        }
    }

    @Test("Init from float literal")
    func floatLiteral() async throws {
        let value: OpenFeatureFieldValue = 42.0

        guard case .double(42) = value else {
            Issue.record("\(value)")
            return
        }
    }
}
