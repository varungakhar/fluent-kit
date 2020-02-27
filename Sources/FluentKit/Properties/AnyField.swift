public protocol PropertyProtocol: AnyProperty {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var value: Value? { get set }
}

public protocol AnyProperty: class {
    func input(to input: inout DatabaseInput)
    func output(from output: DatabaseOutput) throws
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

public protocol FieldProtocol: AnyField, PropertyProtocol {
    associatedtype FieldValue: Codable
    var fieldValue: FieldValue? { get set }
}

extension FieldProtocol where FieldValue == Value {
    public var fieldValue: FieldValue? {
        get {
            self.value
        }
        set {
            self.value = newValue
        }
    }
}

extension FieldProtocol {
    public var anyFieldValue: Any? {
        self.fieldValue
    }

    public var anyFieldValueType: Any.Type {
        FieldValue.self
    }
}

public protocol AnyField: AnyProperty {
    var key: FieldKey { get }
    var anyFieldValue: Any? { get }
    var anyFieldValueType: Any.Type { get }
}

// MARK: Query Builder

public protocol FilterField {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var path: [FieldKey] { get }
}

public protocol QueryField: FilterField {
    var key: FieldKey { get }
}

extension QueryField {
    public var path: [FieldKey] {
        [self.key]
    }
}
