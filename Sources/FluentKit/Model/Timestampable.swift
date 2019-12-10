extension AnyModel {
    var timestamps: [(String, AnyTimestamp)] {
        return self.properties.compactMap { (label, property) in
            guard let field = property as? AnyTimestamp else {
                return nil
            }
            return (label, field)
        }
    }
    func touchTimestamps(_ triggers: TimestampTrigger...) {
        return self.touchTimestamps(triggers)
    }

    private func touchTimestamps(_ triggers: [TimestampTrigger]) {
        let date = Date()
        self.timestamps.forEach { (label, timestamp) in
            if triggers.contains(timestamp.trigger) {
                timestamp.touch(date: date)
            }
        }
    }

    var deletedTimestamp: AnyTimestamp? {
        return self.timestamps.filter({ $0.1.trigger == .delete }).first?.1
    }

    func excludeDeleted(from query: inout DatabaseQuery) {
        guard let timestamp = self.deletedTimestamp else {
            return
        }

        let deletedAtField = DatabaseQuery.Field.field(
            path: [timestamp.key],
            schema: Self.schema,
            alias: nil
        )
        let isNull = DatabaseQuery.Filter.value(deletedAtField, .equal, .null)
        let isFuture = DatabaseQuery.Filter.value(deletedAtField, .greaterThan, .bind(Date()))
        query.filters.append(.group([isNull, isFuture], .or))
    }
}

protocol AnyTimestamp {
    var key: String { get }
    var trigger: TimestampTrigger { get }
    func touch(date: Date?)
}

extension AnyTimestamp {
    public func touch() {
        self.touch(date: .init())
    }
}

extension Model {
    public typealias Timestamp = ModelTimestamp<Self>
}

public enum TimestampTrigger {
    case create
    case update
    case delete
}

@propertyWrapper
public final class ModelTimestamp<Base>: AnyField, FieldRepresentable, AnyTimestamp
    where Base: Model
{
    public typealias Value = Date?

    public let field: ModelField<Base, Date?>

    public let trigger: TimestampTrigger

    public var key: String {
        return self.field.key
    }

    var inputValue: DatabaseQuery.Value? {
        get {
            return self.field.inputValue
        }
        set {
            self.field.inputValue = newValue
        }
    }

    public var projectedValue: ModelTimestamp<Base> {
        return self
    }

    public var wrappedValue: Date? {
        get {
            return self.field.wrappedValue
        }
        set {
            self.field.wrappedValue = newValue
        }
    }

    public init(key: String, on trigger: TimestampTrigger) {
        self.field = .init(key: key)
        self.trigger = trigger
    }

    public func touch(date: Date?) {
        self.inputValue = .bind(date)
    }

    func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}

//public protocol Timestampable: Model, _AnyTimestampable {
//    var createdAt: Date? { get set }
//    var updatedAt: Date? { get set }
//}
//
//
//public protocol _AnyTimestampable {
//    var _createdAtField: Field<Date?> { get }
//    var _updatedAtField: Field<Date?> { get }
//}
//
//extension Timestampable {
//    public var _createdAtField: Field<Date?> {
//        guard let createdAt = Mirror(reflecting: self).descendant("_createdAt") else {
//            fatalError("createdAt must be declared using @Field")
//        }
//        return createdAt as! Field<Date?>
//    }
//
//    public var _updatedAtField: Field<Date?> {
//        guard let updatedAt = Mirror(reflecting: self).descendant("_updatedAt") else {
//            fatalError("updatedAt must be declared using @Field")
//        }
//        return updatedAt as! Field<Date?>
//    }
//}
