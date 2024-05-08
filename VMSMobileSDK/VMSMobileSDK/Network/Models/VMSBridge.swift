//
//  VMSBridge.swift
//  VMSMobileSDK
//
//  Created by Olga Podoliakina on 4.01.24.
//

import Foundation

public class VMSBridge: Decodable {
    
    public let id: Int
    public var name: String?
    public var uuid: String?
    public var serialNumber: String?
    public var mac: String?
    public var status: String?
    public var isOnline: Bool
    public var updatedAt: Date?
    public var createdAt: Date?
    public var storages: [VMSBridgeStorage]?
    public var camerasCount: Int
    public var version: String?
    public var lastUpdatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, uuid, serialNumber, createdAt, mac, status, isOnline, updatedAt, storages, camerasCount, version, lastUpdatedAt
    }
    
    required public init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: CodingKeys.self)
        id = try container.decode (Int.self, forKey: .id)
        name = try? container.decodeIfPresent (String.self, forKey: .name)
        uuid = try? container.decodeIfPresent (String.self, forKey: .uuid)
        serialNumber = try? container.decodeIfPresent(String.self, forKey: .serialNumber)
        mac = try? container.decodeIfPresent(String.self, forKey: .mac)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        isOnline = (try? container.decodeIfPresent(Bool.self, forKey: .isOnline)) ?? false
        storages = try? container.decodeIfPresent([VMSBridgeStorage].self, forKey: .storages)
        camerasCount = (try? container.decodeIfPresent(Int.self, forKey: .camerasCount)) ?? 0
        version = try? container.decodeIfPresent(String.self, forKey: .version)
        
        let created = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        createdAt = DateFormatter.serverUTC.date(from: (created ?? "")) ?? Date()
        let updated = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
        updatedAt = DateFormatter.serverUTC.date(from: (updated ?? "")) ?? Date()
        let lastupdated = try? container.decodeIfPresent(String.self, forKey: .lastUpdatedAt)
        lastUpdatedAt = DateFormatter.serverUTC.date(from: (lastupdated ?? "")) ?? Date()
    }
    
}
