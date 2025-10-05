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

#if DistributedTracingSupport
import ServiceContextModule
import Synchronization
import Tracing

final class SingleSpanTracer: Tracer {
    var span: Span? { _span.withLock(\.self) }
    private let _span = Mutex<Span?>(nil)

    func inject<Carrier, Inject>(
        _ context: ServiceContext,
        into carrier: inout Carrier,
        using injector: Inject
    ) where Carrier == Inject.Carrier, Inject: Injector {}

    func extract<Carrier, Extract>(
        _ carrier: Carrier,
        into context: inout ServiceContext,
        using extractor: Extract
    ) where Carrier == Extract.Carrier, Extract: Extractor {}

    func forceFlush() {}

    func startSpan<Instant>(
        _ operationName: String,
        context: @autoclosure () -> ServiceContext,
        ofKind kind: SpanKind,
        at instant: @autoclosure () -> Instant,
        function: String,
        file fileID: String,
        line: UInt
    ) -> Span where Instant: TracerInstant {
        let span = Span(
            context: context(),
            operationName: operationName,
            attributes: [:],
            isRecording: true
        )
        self._span.withLock { $0 = span }
        return span
    }

    func activeSpan(identifiedBy context: ServiceContext) -> Span? {
        _span.withLock(\.self)
    }

    final class Span: Tracing.Span {
        let context: ServiceContext
        let isRecording: Bool

        var operationName: String {
            get {
                _operationName.withLock(\.self)
            }
            set {
                _operationName.withLock { $0 = newValue }
            }
        }
        private let _operationName: Mutex<String>

        var attributes: SpanAttributes {
            get {
                _attributes.withLock(\.self)
            }
            set {
                _attributes.withLock { $0 = newValue }
            }
        }
        private let _attributes: Mutex<SpanAttributes>

        var events: [SpanEvent] {
            get {
                _events.withLock(\.self)
            }
            set {
                _events.withLock { $0 = newValue }
            }
        }
        private let _events = Mutex<[SpanEvent]>([])

        var errors: [(any Error, SpanAttributes)] {
            get {
                _errors.withLock(\.self)
            }
            set {
                _errors.withLock { $0 = newValue }
            }
        }
        private let _errors = Mutex<[(any Error, SpanAttributes)]>([])

        var status: SpanStatus? {
            get {
                _status.withLock(\.self)
            }
            set {
                _status.withLock { $0 = newValue }
            }
        }
        private let _status = Mutex<SpanStatus?>(nil)

        init(context: ServiceContext, operationName: String, attributes: SpanAttributes, isRecording: Bool) {
            self.context = context
            self._operationName = Mutex(operationName)
            self._attributes = Mutex(attributes)
            self.isRecording = isRecording
        }

        func setStatus(_ status: SpanStatus) {
            _status.withLock { $0 = status }
        }

        func addEvent(_ event: SpanEvent) {
            _events.withLock { $0.append(event) }
        }

        func recordError(
            _ error: any Error,
            attributes: SpanAttributes,
            at instant: @autoclosure () -> some TracerInstant
        ) {
            _errors.withLock { $0.append((error, attributes)) }
        }

        func addLink(_ link: SpanLink) {}

        func end(at instant: @autoclosure () -> some TracerInstant) {}
    }
}
#endif
