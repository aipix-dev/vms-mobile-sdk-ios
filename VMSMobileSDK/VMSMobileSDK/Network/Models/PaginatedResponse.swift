
import Foundation

public struct PaginatedResponse<T: Decodable>: Decodable {
    public let data: [T]
    public let links: Links
    public let meta: Meta
}

public struct Links: Decodable {
    public let first: String?
    public let last: String?
    public let next: String?
    public let prev: String?
}

public struct Meta: Decodable {
    public let currentPage: Int
    public let lastPage: Int?
    public let path: String?
    public let perPage: Int
    public let total: Int
}
