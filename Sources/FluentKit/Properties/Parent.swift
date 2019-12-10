extension Model {
    public typealias Parent<To> = ModelParent<Self, To>
        where To: Model
}

@propertyWrapper
public final class ModelParent<From, To>
    where From: Model, To: Model
{
    @ModelField<From, To.IDValue>
    public var id: To.IDValue

    public var wrappedValue: To {
        get {
            guard let value = self.eagerLoadedValue else {
                fatalError("Parent relation not eager loaded, use $ prefix to access")
            }
            return value
        }
        set { fatalError("use $ prefix to access") }
    }

    public var projectedValue: ModelParent<From, To> {
        return self
    }

    var eagerLoadedValue: To?

    public init(key: String) {
        self._id = .init(key: key)
    }

    public func query(on database: Database) -> QueryBuilder<To> {
        return To.query(on: database)
            .filter(\._$id == self.id)
    }

    public func get(on database: Database) -> EventLoopFuture<To> {
        return self.query(on: database).first().flatMapThrowing { parent in
            guard let parent = parent else {
                throw FluentError.missingParent
            }
            return parent
        }
    }

}

extension ModelParent: FieldRepresentable {
    public var field: ModelField<From, To.IDValue> {
        return self.$id
    }
}

extension ModelParent: AnyProperty {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let parent = self.eagerLoadedValue {
            try container.encode(parent)
        } else {
            try container.encode([
                To.key(for: \._$id): self.id
            ])
        }
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _ModelCodingKey.self)
        try self.$id.decode(from: container.superDecoder(forKey: .string(To.key(for: \._$id))))
        // TODO: allow for nested decoding
    }
}

extension ModelParent: AnyField { }
