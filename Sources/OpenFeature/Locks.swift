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

//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#else
#error("Unsupported runtime")
#endif

final class ReadWriteLock {
    private let rwlock: UnsafeMutablePointer<pthread_rwlock_t> = UnsafeMutablePointer.allocate(capacity: 1)

    init() {
        let err = pthread_rwlock_init(rwlock, nil)
        precondition(err == 0, "pthread_rwlock_init failed with error \(err)")
    }

    deinit {
        let err = pthread_rwlock_destroy(rwlock)
        precondition(err == 0, "pthread_rwlock_destroy failed with error \(err)")
        rwlock.deallocate()
    }

    func lockRead() {
        let err = pthread_rwlock_rdlock(rwlock)
        precondition(err == 0, "pthread_rwlock_rdlock failed with error \(err)")
    }

    func lockWrite() {
        let err = pthread_rwlock_wrlock(rwlock)
        precondition(err == 0, "pthread_rwlock_wrlock failed with error \(err)")
    }

    func unlock() {
        let err = pthread_rwlock_unlock(rwlock)
        precondition(err == 0, "pthread_rwlock_unlock failed with error \(err)")
    }
}

extension ReadWriteLock {
    @inlinable
    func withWriterLock<T>(_ body: () throws -> T) rethrows -> T {
        lockWrite()
        defer {
            unlock()
        }
        return try body()
    }

    @inlinable
    func withReaderLock<T>(_ body: () throws -> T) rethrows -> T {
        lockRead()
        defer {
            unlock()
        }
        return try body()
    }
}
