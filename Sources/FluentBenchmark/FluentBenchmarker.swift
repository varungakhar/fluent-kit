import FluentKit
import Foundation
import NIO
import XCTest

open class FluentBenchmarker: XCTestCase {
    public static var idKey: String = "id"

    open var database: Database! {
        nil
    }

    // MARK: Utilities

    open override func perform(_ run: XCTestRun) {
        if type(of: self) != FluentBenchmarker.self {
            super.perform(run)
        }
    }

    internal func runTest(_ name: String, _ migrations: [Migration], _ test: () throws -> ()) throws {
        self.log("Running \(name)...")
        for migration in migrations {
            do {
                try migration.prepare(on: self.database).wait()
            } catch {
                self.log("Migration failed: \(error) ")
                self.log("Attempting to revert existing migrations...")
                try migration.revert(on: self.database).wait()
                try migration.prepare(on: self.database).wait()
            }
        }
        var e: Error?
        do {
            try test()
        } catch {
            e = error
        }
        for migration in migrations.reversed() {
            try migration.revert(on: self.database).wait()
        }
        if let error = e {
            throw error
        }
    }
    
    private func log(_ message: String) {
        print("[FluentBenchmark] \(message)")
    }
}
