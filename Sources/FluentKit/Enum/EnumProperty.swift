extension Fields {
    public typealias Enum<Value> = EnumProperty<Self, Value>
        where Value: Codable,
            Value: RawRepresentable,
            Value.RawValue == String
}

@propertyWrapper
public final class EnumProperty<Model, Value>
    where Model: FluentKit.Fields,
        Value: Codable,
        Value: RawRepresentable,
        Value.RawValue == String
{
    public let field: FieldProperty<Model, String>

    public var projectedValue: EnumProperty<Model, Value> {
        return self
    }

    public var wrappedValue: Value {
        get {
            guard let value = self.value else {
                fatalError("Cannot access enum value before initialized.")
            }
            return value
        }
        set {
            self.value = newValue
        }
    }

    public init(key: FieldKey) {
        self.field = .init(key: key)
    }
}

extension EnumProperty: FilterField {
    public var path: [FieldKey] {
        self.field.path
    }
}

extension EnumProperty: FieldProtocol {
    public typealias FieldValue = String

    public var fieldValue: String? {
        get {
            self.field.fieldValue
        }
        set {
            self.field.fieldValue = newValue
        }
    }

}

extension EnumProperty: AnyField {
    public var key: FieldKey {
        self.field.key
    }
}

extension EnumProperty: PropertyProtocol {
    public var value: Value? {
        get {
            if let value = self.field.inputValue {
                switch value {
                case .enumCase(let string):
                    return Value(rawValue: string)!
                default:
                    return nil
                }
            } else if let value = self.field.outputValue {
                return Value(rawValue: value)!
            } else {
                return nil
            }
        }
        set {
            self.field.inputValue = newValue.flatMap {
                .enumCase($0.rawValue)
            }
        }
    }


}

extension EnumProperty: AnyProperty {
    public func input(to input: inout DatabaseInput) {
        self.field.input(to: &input)
    }

    public func output(from output: DatabaseOutput) throws {
        try self.field.output(from: output)
    }

    public func encode(to encoder: Encoder) throws {
        try self.field.encode(to: encoder)
    }

    public func decode(from decoder: Decoder) throws {
        try self.field.decode(from: decoder)
    }
}
