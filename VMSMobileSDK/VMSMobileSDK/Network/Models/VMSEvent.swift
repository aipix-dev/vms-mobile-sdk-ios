
import Foundation

public final class VMSEvent: Decodable {
    
    public var id: Int?
    public var title: String?
    public var from: Date?
    public var to: Date?
    public var createdAt: Date?
    public var camera: VMSCamera?
    public var type: String?
    public var typePretty: String?
    public var canDelete: Bool?
    public var analyticCase: VMSAnalyticCase?
    public var analyticFile: VMSAnalyticFile?
    public var analyticGroup: VMSAnalyticGroup?
    public var event: VMSAnalyticEvent?
    public var crop: String?
    public var similarity: Double?
    public var rect: Int?
    public var licensePlate: String?
    public var containerCode: String?
    public var containerDimsCode: String?
    
    public init(id: Int, from: Date, title: String?) {
        self.id = id
        self.from = from
        self.title = title
        self.type = VMSEventType.defaultType
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, camera, canDelete, typePretty, type, createdAt, from, to, analyticCase, analyticFile, analyticGroup, event, crop, similarity, rect, licensePlate, containerCode, containerDimsCode
        // Socket push data
        case caseType, analyticCaseId
    }
    
    public init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent(Int.self, forKey: .id)
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        camera = try? container.decodeIfPresent(VMSCamera.self, forKey: .camera)
        canDelete = try? container.decodeIfPresent(Bool.self, forKey: .canDelete)
        typePretty = try? container.decodeIfPresent(String.self, forKey: .typePretty)
        type = try container.decodeIfPresent (String.self, forKey: .type)
        
        let created = try container.decodeIfPresent(String.self, forKey: .createdAt)
        createdAt = DateFormatter.serverUTC.date(from: (created ?? "")) ?? Date()
        if let fromDate = try container.decodeIfPresent(String.self, forKey: .from) {
            from = DateFormatter.serverUTC.date(from: (fromDate)) ?? Date()
        }
        if let toDate = try container.decodeIfPresent(String.self, forKey: .to) {
            to = DateFormatter.serverUTC.date(from: (toDate)) ?? Date()
        }
        
        analyticCase = try? container.decodeIfPresent(VMSAnalyticCase.self, forKey: .analyticCase)
        analyticFile = try? container.decodeIfPresent(VMSAnalyticFile.self, forKey: .analyticFile)
        analyticGroup = try? container.decodeIfPresent(VMSAnalyticGroup.self, forKey: .analyticGroup)
        event = try? container.decodeIfPresent(VMSAnalyticEvent.self, forKey: .event)
        crop = try? container.decodeIfPresent(String.self, forKey: .crop)
        similarity = try? container.decodeIfPresent(Double.self, forKey: .similarity)
        rect = try? container.decodeIfPresent(Int.self, forKey: .rect)
        licensePlate = try? container.decodeIfPresent(String.self, forKey: .licensePlate)
        containerCode = try? container.decodeIfPresent(String.self, forKey: .containerCode)
        containerDimsCode = try? container.decodeIfPresent(String.self, forKey: .containerDimsCode)
        
        let caseType = try container.decodeIfPresent(String.self, forKey: .caseType)
        let analyticCaseId = try container.decodeIfPresent(Int.self, forKey: .analyticCaseId)
        
        if let caseType, let analyticCaseId, analyticCase == nil {
            analyticCase = VMSAnalyticCase(id: analyticCaseId, type: caseType)
            if type == nil {
                type = caseType
            }
        }
    }
}

extension VMSEvent: VMSAnalyticType {
    public func getId() -> Int {
        return id ?? -1
    }
    
    public func typeName() -> String {
        return type ?? VMSEventType.defaultType
    }
    
    public func titleName() -> String {
        return title ?? typePretty ?? ""
    }
}
