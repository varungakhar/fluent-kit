import FluentSQL

extension FluentBenchmarker {
    public func testModel() throws {
        try self.testModel_uuid()
        try self.testModel_decode()
        try self.testModel_nullField()
        try self.testModel_idGeneration()
        try self.testModel_jsonColumn()
    }

    private func testModel_uuid() throws {
        try self.runTest(#function, [
            UserMigration(),
        ]) {
            try User(name: "Vapor")
                .save(on: self.database).wait()
            let count = try User.query(on: self.database).count().wait()
            XCTAssertEqual(count, 1, "User did not save")
        }
    }

    private func testModel_decode() throws {
        try self.runTest(#function, [
            TodoMigration(),
        ]) {
            let todo = """
            {"title": "Finish Vapor 4"}
            """
            try JSONDecoder().decode(Todo.self, from: todo.data(using: .utf8)!)
                .save(on: self.database).wait()
            guard try Todo.query(on: self.database).count().wait() == 1 else {
                XCTFail("Todo did not save")
                return
            }
        }
    }

    private func testModel_nullField() throws {
        try runTest(#function, [
            FooMigration(),
        ]) {
            let foo = Foo(bar: "test")
            try foo.save(on: self.database).wait()
            guard foo.bar != nil else {
                XCTFail("unexpected nil value")
                return
            }
            foo.bar = nil
            try foo.save(on: self.database).wait()
            guard foo.bar == nil else {
                XCTFail("unexpected non-nil value")
                return
            }

            guard let fetched = try Foo.query(on: self.database)
                .filter(\.$id == foo.id!)
                .first().wait()
            else {
                XCTFail("no model returned")
                return
            }
            guard fetched.bar == nil else {
                XCTFail("unexpected non-nil value")
                return
            }
        }
    }

    private func testModel_idGeneration() throws {
        try runTest(#function, [
            GalaxyMigration(),
        ]) {
            let galaxy = Galaxy(name: "Milky Way")
            guard galaxy.id == nil else {
                XCTFail("id should not be set")
                return
            }
            try galaxy.save(on: self.database).wait()

            let a = Galaxy(name: "A")
            let b = Galaxy(name: "B")
            let c = Galaxy(name: "C")
            try a.save(on: self.database).wait()
            try b.save(on: self.database).wait()
            try c.save(on: self.database).wait()
            guard a.id != b.id && b.id != c.id && a.id != c.id else {
                XCTFail("ids should not be equal")
                return
            }
        }
    }

    private func testModel_jsonColumn() throws {
        try runTest(#function, [
            BarMigration(),
        ]) {
            let bar = Bar(baz: .init(quux: "test"))
            try bar.save(on: self.database).wait()

            let fetched = try Bar.find(bar.id, on: self.database).wait()
            XCTAssertEqual(fetched?.baz.quux, "test")

            if self.database is SQLDatabase {
                let bars = try Bar.query(on: self.database)
                    .filter(.sql(json: "baz", "quux"), .equal, .bind("test"))
                    .all()
                    .wait()
                XCTAssertEqual(bars.count, 1)
            }
        }
    }
}

private final class Foo: Model {
    static let schema = "foos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "bar")
    var bar: String?

    init() { }

    init(id: IDValue? = nil, bar: String?) {
        self.id = id
        self.bar = bar
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("foos").delete()
    }
}

private final class User: Model {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    init() { }
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

private struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

private final class Todo: Model {
    static let schema = "todos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    init() { }
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

private struct TodoMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("todos")
            .field("id", .uuid, .identifier(auto: false))
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("todos").delete()
    }
}

private final class Bar: Model {
    static let schema = "bars"

    @ID
    var id: UUID?

    struct Baz: Codable {
        var quux: String
    }

    @Field(key: "baz")
    var baz: Baz

    init() { }

    init(id: IDValue? = nil, baz: Baz) {
        self.id = id
        self.baz = baz
    }
}

private struct BarMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("bars")
            .field("id", .uuid, .identifier(auto: false))
            .field("baz", .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("bars").delete()
    }
}
