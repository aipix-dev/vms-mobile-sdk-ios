//
//  VMSBridgeStorage.swift
//  VMSMobileSDK
//
//  Created by Olga Podoliakina on 4.01.24.
//

import Foundation

public class VMSBridgeStorage: Decodable {
    
    public let id: Int
    public var path: String?
    public var usage: Double
    public var capacity: Double
    
}
