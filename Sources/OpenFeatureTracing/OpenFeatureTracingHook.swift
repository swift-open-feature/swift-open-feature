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
import Tracing

public struct OpenFeatureTracingHook: OpenFeatureHook {
    private let setSpanStatusOnError: Bool
    private let recordTargetingKey: Bool

    public init(
        setSpanStatusOnError: Bool = false,
        recordTargetingKey: Bool = false
    ) {
        self.setSpanStatusOnError = setSpanStatusOnError
        self.recordTargetingKey = recordTargetingKey
    }

    public func afterSuccessfulEvaluation(
        context: OpenFeatureHookContext,
        evaluation: OpenFeatureEvaluation<some OpenFeatureValue>,
        hints: OpenFeatureHookHints
    ) throws {
        guard let serviceContext = ServiceContext.current,
            let span = InstrumentationSystem.tracer.activeSpan(identifiedBy: serviceContext)
        else { return }

        var eventAttributes: SpanAttributes = [
            "feature_flag.key": "\(context.flag)"
        ]

        if let providerMetadata = context.providerMetadata {
            eventAttributes["feature_flag.provider_name"] = providerMetadata.name
        }

        if let variant = evaluation.variant {
            eventAttributes["feature_flag.variant"] = variant
        }

        if recordTargetingKey, let targetingKey = context.evaluationContext.targetingKey {
            eventAttributes["feature_flag.context.id"] = targetingKey
        }

        span.addEvent(SpanEvent(name: "feature_flag", attributes: eventAttributes))
    }

    public func onError(context: OpenFeatureHookContext, error: any Error, hints: OpenFeatureHookHints) {
        guard let serviceContext = ServiceContext.current,
            let span = InstrumentationSystem.tracer.activeSpan(identifiedBy: serviceContext)
        else { return }

        let errorType: String
        let evaluationErrorMessage: String?
        if let error = error as? OpenFeatureResolutionError {
            errorType = error.code.rawValue.lowercased()
            evaluationErrorMessage = error.message
        } else {
            errorType = "general"
            evaluationErrorMessage = nil
        }

        var eventAttributes: SpanAttributes = [
            "feature_flag.key": "\(context.flag)",
            "error.type": "\(errorType)"
        ]

        if let providerMetadata = context.providerMetadata {
            eventAttributes["feature_flag.provider_name"] = providerMetadata.name
        }

        if recordTargetingKey, let targetingKey = context.evaluationContext.targetingKey {
            eventAttributes["feature_flag.context.id"] = targetingKey
        }

        if let evaluationErrorMessage {
            eventAttributes["feature_flag.evaluation.error.message"] = evaluationErrorMessage
        }

        span.recordError(error, attributes: eventAttributes)

        if setSpanStatusOnError {
            let message = #"Error evaluating flag "\#(context.flag)" of type "\#(type(of: context.defaultValue))"."#
            span.setStatus(SpanStatus(code: .error, message: message))
        }
    }
}
