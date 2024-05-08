
import Foundation

public final class VMSCameraTree: Decodable {
    
    public var cameras: [VMSCamera]!
    public var children: [VMSCameraTree]?
    public var mainName: String?
    public var hasCameras: Bool = false
    public var subMain: String?
    public var previews: [VMSCameraPreview]?
    
    public init(cameras: [VMSCamera]) {
        self.cameras = cameras
        self.children = []
    }
    
    enum CodingKeys: String, CodingKey {
        case mainName
        case subMain
        case id
        case cameras
        case children
        case hasCameras
        case previews
    }
    
    public init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: CodingKeys.self)
        subMain = try? container.decode (String.self, forKey: .subMain)
        children = try? container.decode([VMSCameraTree].self, forKey: .children)
        mainName = try? container.decodeIfPresent(String.self, forKey: .mainName)
        hasCameras = try container.decodeIfPresent (Bool.self, forKey: .hasCameras) ?? false
        previews = try? container.decodeIfPresent([VMSCameraPreview].self, forKey: .previews)
        cameras = try? container.decodeIfPresent ([VMSCamera].self, forKey: .cameras) ?? []
    }
}

extension VMSCameraTree {
    
    public func getAllCameras() -> [VMSCamera] {
        var activeCameras = [VMSCamera]()
        if cameras.count > 0 {
            activeCameras.append(contentsOf: cameras)
        }
        for tree in children ?? [] {
            let innerCameras = tree.getAllCameras()
            activeCameras.append(contentsOf: innerCameras)
        }
        return activeCameras
    }
}
