import Foundation

public enum OpenFeatureFieldValue {
    case bool(Bool)
    case string(String)
    case int(Int)
    case double(Double)
    case date(Date)
    case object(any Codable & Sendable)
}
