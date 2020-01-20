import XCTest

extension FluentBenchmarker {
    public func testEnums() throws {
        try self.runTest(#function, [
            _PlanetMigration()
        ]) {
            try _Planet(name: "Earth", type: .smallRocky).save(on: self.database).wait()
            try _Planet(name: "Jupiter", type: .gasGiant).save(on: self.database).wait()
            let planets = try _Planet.query(on: self.database).all().wait()
            for planet in planets {
                switch (planet.name, planet.type) {
                case ("Earth", .smallRocky),
                     ("Jupiter", .gasGiant),
                    // success
                    break
                default:
                    XCTFail("unexpected planet / type combination: \(planet.name) \(planet.type)")
                }
            }
        }
    }
}

final class _Planet: Model {
    static let schema = "planets"

    @ID(key: "id")
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "type")
    var type: PlanetType

    init() { }

    init(id: UUID? = nil, name: String, type: PlanetType) {
        self.id = id
        self.name = name
        self.type = type
    }
}

enum PlanetType: String, Codable, DatabaseEnum {
    case smallRocky
    case gasGiant
    case dwarf
}

struct _PlanetMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("PLANET_TYPE")
            .case("smallRocky")
            .case("gasGiant")
            .create()
            .flatMap
        {
            database.schema("planets")
                .field("id", .uuid, .identifier(auto: false))
                .field("name", .string, .required)
                .field("type", .enum("PLANET_TYPE"), .required)
                .create()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("planets").delete().flatMap {
            database.enum("PLANET_TYPE").delete()
        }
    }
}

struct _PlanetTypeAddDwarf: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.type(enum: "PLANET_TYPE")
            .case("dwarf")
            .update()
            .flatMap
        { planetType in
            database.schema("planets")
                .field("type", .enum(planetType), .required)
                .update()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.type(enum: "PLANET_TYPE")
            .deleteCase("dwarf")
            .update()
    }
}
