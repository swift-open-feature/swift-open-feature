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
import OpenFeatureTestSupport
import Synchronization
import Testing

@Suite("OpenFeatureCliet")
struct OpenFeatureClientTests {
    @Suite("Bool")
    struct BoolTests {
        @Test("value", arguments: [true, false])
        func value(_ value: Bool) async {
            let provider = OpenFeatureStaticProvider(boolResolution: OpenFeatureResolution(value: value))
            let client = OpenFeatureClient(provider: { provider })

            let resolvedValue = await client.value(for: "flag", defaultingTo: !value)

            #expect(resolvedValue == value)
        }

        @Test("evaluation", arguments: [true, false])
        func evaluation(_ value: Bool) async {
            let provider = OpenFeatureStaticProvider(boolResolution: OpenFeatureResolution(value: value))
            let client = OpenFeatureClient(provider: { provider })

            let evaluation = await client.evaluation(of: "flag", defaultingTo: !value)

            #expect(evaluation == OpenFeatureEvaluation(flag: "flag", value: value))
        }
    }

    @Suite("String")
    struct StringTests {
        @Test("value", arguments: ["foo", "bar"])
        func value(_ value: String) async {
            let provider = OpenFeatureStaticProvider(stringResolution: OpenFeatureResolution(value: value))
            let client = OpenFeatureClient(provider: { provider })

            let resolvedValue = await client.value(for: "flag", defaultingTo: "some-default-value")

            #expect(resolvedValue == value)
        }

        @Test("evaluation", arguments: ["foo", "bar"])
        func evaluation(_ value: String) async {
            let provider = OpenFeatureStaticProvider(stringResolution: OpenFeatureResolution(value: value))
            let client = OpenFeatureClient(provider: { provider })

            let evaluation = await client.evaluation(of: "flag", defaultingTo: "some-default-value")

            #expect(evaluation == OpenFeatureEvaluation(flag: "flag", value: value))
        }
    }

    @Suite("Int")
    struct IntTests {
        @Test("value", arguments: [-42, 0, 42])
        func value(_ value: Int) async {
            let provider = OpenFeatureStaticProvider(intResolution: OpenFeatureResolution(value: value))
            let client = OpenFeatureClient(provider: { provider })

            let resolvedValue = await client.value(for: "flag", defaultingTo: 1000)

            #expect(resolvedValue == value)
        }

        @Test("evaluation", arguments: [-42, 0, 42])
        func evaluation(_ value: Int) async {
            let provider = OpenFeatureStaticProvider(intResolution: OpenFeatureResolution(value: value))
            let client = OpenFeatureClient(provider: { provider })

            let evaluation = await client.evaluation(of: "flag", defaultingTo: 1000)

            #expect(evaluation == OpenFeatureEvaluation(flag: "flag", value: value))
        }
    }

    @Suite("Double")
    struct DoubleTests {
        @Test("value", arguments: [-4.2, 0.0, 4.2])
        func value(_ value: Double) async {
            let provider = OpenFeatureStaticProvider(doubleResolution: OpenFeatureResolution(value: value))
            let client = OpenFeatureClient(provider: { provider })

            let resolvedValue = await client.value(for: "flag", defaultingTo: 1000.0)

            #expect(resolvedValue == value)
        }

        @Test("evaluation", arguments: [-4.2, 0.0, 4.2])
        func evaluation(_ value: Double) async {
            let provider = OpenFeatureStaticProvider(doubleResolution: OpenFeatureResolution(value: value))
            let client = OpenFeatureClient(provider: { provider })

            let evaluation = await client.evaluation(of: "flag", defaultingTo: 1000.0)

            #expect(evaluation == OpenFeatureEvaluation(flag: "flag", value: value))
        }
    }

    @Suite("Evaluation Context Merging")
    struct EvaluationContextMergingTests {
        @Test("Starts with global")
        func globalContextOnly() async throws {
            let globalContext = OpenFeatureEvaluationContext(targetingKey: "global", fields: ["global": 42])
            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider }, globalEvaluationContext: { globalContext })

            #expect(await client.value(for: "flag", defaultingTo: true) == true)

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "global")
            #expect(request.context?.fields["global"]?.intValue == 42)
        }

        @Test("Task-local overrides global")
        func taskLocalOverridesGlobal() async throws {
            let globalContext = OpenFeatureEvaluationContext(
                targetingKey: "global",
                fields: ["global": 42, "shared": "global"]
            )
            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider }, globalEvaluationContext: { globalContext })

            let taskLocalContext = OpenFeatureEvaluationContext(
                targetingKey: "task-local",
                fields: ["task-local": 42, "shared": "task-local"]
            )

            await OpenFeatureEvaluationContext.$current.withValue(taskLocalContext) {
                #expect(await client.value(for: "flag", defaultingTo: true) == true)
            }

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "task-local")
            #expect(request.context?.fields["global"]?.intValue == 42)
            #expect(request.context?.fields["task-local"]?.intValue == 42)
            #expect(request.context?.fields["shared"]?.stringValue == "task-local")
        }

        @Test("Client overrides task-local")
        func clientOverridesTaskLocal() async throws {
            let clientContext = OpenFeatureEvaluationContext(
                targetingKey: "client",
                fields: ["client": 42, "shared": "client"]
            )
            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider })
            await client.setEvaluationContext(clientContext)

            let taskLocalContext = OpenFeatureEvaluationContext(
                targetingKey: "task-local",
                fields: ["task-local": 42, "shared": "task-local"]
            )

            await OpenFeatureEvaluationContext.$current.withValue(taskLocalContext) {
                #expect(await client.value(for: "flag", defaultingTo: true) == true)
            }

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "client")
            #expect(request.context?.fields["client"]?.intValue == 42)
            #expect(request.context?.fields["task-local"]?.intValue == 42)
            #expect(request.context?.fields["shared"]?.stringValue == "client")
        }

        @Test("Invocation overrides client")
        func invocationOverridesClient() async throws {
            let clientContext = OpenFeatureEvaluationContext(
                targetingKey: "client",
                fields: ["client": 42, "shared": "client"]
            )
            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider })
            await client.setEvaluationContext(clientContext)

            let invocationContext = OpenFeatureEvaluationContext(
                targetingKey: "invocation",
                fields: ["invocation": 42, "shared": "invocation"]
            )

            #expect(await client.value(for: "flag", defaultingTo: true, context: invocationContext) == true)

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "invocation")
            #expect(request.context?.fields["client"]?.intValue == 42)
            #expect(request.context?.fields["invocation"]?.intValue == 42)
            #expect(request.context?.fields["shared"]?.stringValue == "invocation")
        }

        @Test("Merges all contexts")
        func mergesAllContexts() async throws {
            let globalContext = OpenFeatureEvaluationContext(fields: ["global": 42])
            let taskLocalContext = OpenFeatureEvaluationContext(targetingKey: "task-local", fields: ["task-local": 42])
            let clientContext = OpenFeatureEvaluationContext(fields: ["client": 42])
            let invocationContext = OpenFeatureEvaluationContext(fields: ["invocation": 42])

            let provider = OpenFeatureRecordingProvider()
            let client = OpenFeatureClient(provider: { provider }, globalEvaluationContext: { globalContext })
            await client.setEvaluationContext(clientContext)

            await OpenFeatureEvaluationContext.$current.withValue(taskLocalContext) {
                #expect(await client.value(for: "flag", defaultingTo: true, context: invocationContext) == true)
            }

            let request = try #require(await provider.boolResolutionRequests.first)
            #expect(request.context?.targetingKey == "task-local")
            #expect(request.context?.fields["global"]?.intValue == 42)
            #expect(request.context?.fields["task-local"]?.intValue == 42)
            #expect(request.context?.fields["client"]?.intValue == 42)
            #expect(request.context?.fields["invocation"]?.intValue == 42)
        }
    }

    @Suite("Hooks")
    struct HookTests {
        @Suite("Ordering")
        struct OrderingTests {
            @Test("Before")
            func beforeHooksOrder() async throws {
                // global -> client -> invocation -> provider
                let hookInvocations = Mutex<[String]>([])

                let globalHook = OpenFeatureClosureHook(beforeEvaluation: { context, _ in
                    context.evaluationContext.fields["global"] = "global"
                    hookInvocations.withLock { $0.append("global") }
                })
                let clientHook = OpenFeatureClosureHook(beforeEvaluation: { context, _ in
                    context.evaluationContext.fields["client"] = "client"
                    hookInvocations.withLock { $0.append("client") }
                })
                let invocationHook = OpenFeatureClosureHook(beforeEvaluation: { context, _ in
                    context.evaluationContext.fields["invocation"] = "invocation"
                    hookInvocations.withLock { $0.append("invocation") }
                })
                let providerHook = OpenFeatureClosureHook(beforeEvaluation: { context, _ in
                    context.evaluationContext.fields["provider"] = "provider"
                    hookInvocations.withLock { $0.append("provider") }
                })

                let provider = OpenFeatureRecordingProvider(hooks: [providerHook])

                let client = OpenFeatureClient(
                    provider: { provider },
                    hooks: [clientHook],
                    globalHooks: { [globalHook] }
                )

                _ = await client.value(for: "flag", defaultingTo: false, hooks: [invocationHook])

                #expect(hookInvocations.withLock(\.self) == ["global", "client", "invocation", "provider"])

                let request = try #require(await provider.boolResolutionRequests.first)
                #expect(request.context?.fields["global"]?.stringValue == "global")
                #expect(request.context?.fields["client"]?.stringValue == "client")
                #expect(request.context?.fields["invocation"]?.stringValue == "invocation")
                #expect(request.context?.fields["provider"]?.stringValue == "provider")
            }

            @Test("After success")
            func afterSuccessHooksOrder() async throws {
                // provider -> invocation -> client -> global
                let hookInvocations = Mutex<[String]>([])

                let providerHook = OpenFeatureClosureHook(afterSuccessfulEvaluation: { _, _, _ in
                    hookInvocations.withLock { $0.append("provider") }
                })
                let invocationHook = OpenFeatureClosureHook(afterSuccessfulEvaluation: { _, _, _ in
                    hookInvocations.withLock { $0.append("invocation") }
                })
                let clientHook = OpenFeatureClosureHook(afterSuccessfulEvaluation: { _, _, _ in
                    hookInvocations.withLock { $0.append("client") }
                })
                let globalHook = OpenFeatureClosureHook(afterSuccessfulEvaluation: { _, _, _ in
                    hookInvocations.withLock { $0.append("global") }
                })

                let provider = OpenFeatureRecordingProvider(hooks: [providerHook])

                let client = OpenFeatureClient(
                    provider: { provider },
                    hooks: [clientHook],
                    globalHooks: { [globalHook] }
                )

                _ = await client.value(for: "flag", defaultingTo: false, hooks: [invocationHook])

                #expect(hookInvocations.withLock(\.self) == ["provider", "invocation", "client", "global"])
            }

            @Test("Error")
            func errorHooksOrder() async throws {
                // provider -> invocation -> client -> global
                let hookInvocations = Mutex<[String]>([])

                let providerHook = OpenFeatureClosureHook(onError: { _, _, _ in
                    hookInvocations.withLock { $0.append("provider") }
                })
                let invocationHook = OpenFeatureClosureHook(onError: { _, _, _ in
                    hookInvocations.withLock { $0.append("invocation") }
                })
                let clientHook = OpenFeatureClosureHook(onError: { _, _, _ in
                    hookInvocations.withLock { $0.append("client") }
                })
                let globalHook = OpenFeatureClosureHook(onError: { _, _, _ in
                    hookInvocations.withLock { $0.append("global") }
                })

                let provider = OpenFeatureStaticProvider(
                    boolResolution: OpenFeatureResolution(
                        value: false,
                        error: OpenFeatureResolutionError(code: .invalidContext, message: nil)
                    ),
                    hooks: [providerHook]
                )

                let client = OpenFeatureClient(
                    provider: { provider },
                    hooks: [clientHook],
                    globalHooks: { [globalHook] }
                )

                _ = await client.value(for: "flag", defaultingTo: false, hooks: [invocationHook])

                #expect(hookInvocations.withLock(\.self) == ["provider", "invocation", "client", "global"])
            }

            @Test("After")
            func afterHooksOrder() async throws {
                // provider -> invocation -> client -> global
                let hookInvocations = Mutex<[String]>([])

                let providerHook = OpenFeatureClosureHook(afterEvaluation: { _, _, _ in
                    hookInvocations.withLock { $0.append("provider") }
                })
                let invocationHook = OpenFeatureClosureHook(afterEvaluation: { _, _, _ in
                    hookInvocations.withLock { $0.append("invocation") }
                })
                let clientHook = OpenFeatureClosureHook(afterEvaluation: { _, _, _ in
                    hookInvocations.withLock { $0.append("client") }
                })
                let globalHook = OpenFeatureClosureHook(afterEvaluation: { _, _, _ in
                    hookInvocations.withLock { $0.append("global") }
                })

                let provider = OpenFeatureStaticProvider(
                    boolResolution: OpenFeatureResolution(
                        value: false,
                        error: OpenFeatureResolutionError(code: .invalidContext, message: nil)
                    ),
                    hooks: [providerHook]
                )

                let client = OpenFeatureClient(
                    provider: { provider },
                    hooks: [clientHook],
                    globalHooks: { [globalHook] }
                )

                _ = await client.value(for: "flag", defaultingTo: false, hooks: [invocationHook])

                #expect(hookInvocations.withLock(\.self) == ["provider", "invocation", "client", "global"])
            }
        }

        @Suite("Error")
        struct ErrorTests {
            @Test("Resolution error thrown in before hook")
            func beforeHookThrowsResolutionError() async throws {
                let resolutionError = OpenFeatureResolutionError(code: .invalidContext, message: "test")
                let hookError = Mutex<(any Error)?>(nil)
                let afterEvaluationHookCalled = Mutex(false)
                let hook = OpenFeatureClosureHook(
                    beforeEvaluation: { _, _ in throw resolutionError },
                    onError: { _, error, _ in hookError.withLock { $0 = error } },
                    afterEvaluation: { _, _, _ in afterEvaluationHookCalled.withLock { $0 = true } }
                )
                let provider = OpenFeatureNoOpProvider()
                let client = OpenFeatureClient(provider: { provider })
                await client.addHooks([hook])

                let evaluation = await client.evaluation(of: "flag", defaultingTo: false)

                #expect(evaluation.error == resolutionError)
                #expect(hookError.withLock(\.self) as? OpenFeatureResolutionError == resolutionError)
                #expect(afterEvaluationHookCalled.withLock(\.self) == true)
            }

            @Test("Unknown error thrown in before hook")
            func beforeHookThrowsUnknownError() async throws {
                struct TestError: Error, CustomStringConvertible {
                    let description = "Test Error"
                }
                let hookError = Mutex<(any Error)?>(nil)
                let afterEvaluationHookCalled = Mutex(false)
                let hook = OpenFeatureClosureHook(
                    beforeEvaluation: { _, _ in throw TestError() },
                    onError: { _, error, _ in hookError.withLock { $0 = error } },
                    afterEvaluation: { _, _, _ in afterEvaluationHookCalled.withLock { $0 = true } }
                )
                let provider = OpenFeatureNoOpProvider()
                let client = OpenFeatureClient(provider: { provider })
                await client.addHooks([hook])

                let evaluation = await client.evaluation(of: "flag", defaultingTo: false)

                #expect(evaluation.error == OpenFeatureResolutionError(code: .general, message: "Test Error"))
                #expect(hookError.withLock(\.self) is TestError)
                #expect(afterEvaluationHookCalled.withLock(\.self) == true)
            }

            @Test("Resolution error thrown in after success hook")
            func afterSuccessHookThrowsResolutionError() async throws {
                let resolutionError = OpenFeatureResolutionError(code: .invalidContext, message: "test")
                let hookError = Mutex<(any Error)?>(nil)
                let afterEvaluationHookCalled = Mutex(false)
                let hook = OpenFeatureClosureHook(
                    afterSuccessfulEvaluation: { _, _, _ in throw resolutionError },
                    onError: { _, error, _ in hookError.withLock { $0 = error } },
                    afterEvaluation: { _, _, _ in afterEvaluationHookCalled.withLock { $0 = true } }
                )
                let provider = OpenFeatureNoOpProvider()
                let client = OpenFeatureClient(provider: { provider })
                await client.addHooks([hook])

                let evaluation = await client.evaluation(of: "flag", defaultingTo: false)

                #expect(evaluation.error == resolutionError)
                #expect(hookError.withLock(\.self) as? OpenFeatureResolutionError == resolutionError)
                #expect(afterEvaluationHookCalled.withLock(\.self) == true)
            }

            @Test("Unknown error thrown in after success hook")
            func afterSuccessHookThrowsUnknownError() async throws {
                struct TestError: Error, CustomStringConvertible {
                    let description = "Test Error"
                }
                let hookError = Mutex<(any Error)?>(nil)
                let afterEvaluationHookCalled = Mutex(false)
                let hook = OpenFeatureClosureHook(
                    afterSuccessfulEvaluation: { _, _, _ in throw TestError() },
                    onError: { _, error, _ in hookError.withLock { $0 = error } },
                    afterEvaluation: { _, _, _ in afterEvaluationHookCalled.withLock { $0 = true } }
                )
                let provider = OpenFeatureNoOpProvider()
                let client = OpenFeatureClient(provider: { provider })
                await client.addHooks([hook])

                let evaluation = await client.evaluation(of: "flag", defaultingTo: false)

                #expect(evaluation.error == OpenFeatureResolutionError(code: .general, message: "Test Error"))
                #expect(hookError.withLock(\.self) is TestError)
                #expect(afterEvaluationHookCalled.withLock(\.self) == true)
            }

            @Test("Resolving error")
            func providerResolvesError() async throws {
                let hookError = Mutex<(any Error)?>(nil)
                let hook = OpenFeatureClosureHook(onError: { _, error, _ in hookError.withLock { $0 = error } })
                let resolutionError = OpenFeatureResolutionError(code: .flagNotFound, message: #"Flag "💩" not found."#)
                let provider = OpenFeatureStaticProvider(
                    boolResolution: OpenFeatureResolution(value: false, error: resolutionError)
                )
                let client = OpenFeatureClient(provider: { provider })
                await client.addHooks([hook])

                let evaluation = await client.evaluation(of: "💩", defaultingTo: false)

                #expect(evaluation.error == resolutionError)
                #expect(hookError.withLock(\.self) as? OpenFeatureResolutionError == resolutionError)
            }
        }

        @Test("Default implementations don't throw")
        func defaultImplementations() async throws {
            let hook = OpenFeatureNoOpHook()
            let provider = OpenFeatureStaticProvider(boolResolution: OpenFeatureResolution(value: true))
            let client = OpenFeatureClient(provider: { provider }, hooks: [hook])

            let evaluation = await client.evaluation(of: "flag", defaultingTo: false)

            #expect(evaluation == OpenFeatureEvaluation(flag: "flag", value: true, error: nil))
        }

        @Test("Default error implementation")
        func defaultErrorImplementation() async throws {
            let hook = OpenFeatureNoOpHook()
            let provider = OpenFeatureStaticProvider(
                boolResolution: OpenFeatureResolution(
                    value: false,
                    error: OpenFeatureResolutionError(code: .fatal, message: nil)
                )
            )
            let client = OpenFeatureClient(provider: { provider }, hooks: [hook])

            _ = await client.value(for: "flag", defaultingTo: false)
        }
    }
}

private struct OpenFeatureNoOpHook: OpenFeatureHook {}
