
import Foundation

public enum VMSAppSocketType: String, Decodable {
    
    case camerasUpdate = "cameras_updated"
    case removeFavoriteCamera = "camera.destroy_favorite"
    case favoriteCamera = "camera.store_favorite"
    case permissionsUpdate = "permissions_updated"
    case layoutsUpdate = "layouts_updated"
    case groupsUpdate = "groups_updated"
    case groupsCreated = "groups_created"
    case groupsDeleted = "groups_deleted"
    case cameraGroupsSynced = "camera_groups_synced"
    case markCreated = "mark_created"
    case markDeleted = "mark_deleted"
    case markUpdated = "mark_updated"
    case archiveGenerated = "archive_generated" // Token channel
    case logout = "logout" // Token channel
    
    case analyticCaseMotionDetectEventCreated = "analytic_case_motion_detect_event_created"
    case analyticCaseLineIntersectionEventCreated = "analytic_case_line_intersection_event_created"
    case analyticCaseSmokeFireEventCreated = "analytic_case_smoke_fire_event_created"
    case analyticCaseLoudSoundEventCreated = "analytic_case_loud_sound_event_created"
    case analyticCaseCameraObstacleEventCreated = "analytic_case_camera_obstacle_event_created"
    case analyticCaseFaceEventCreated = "analytic_case_face_event_created"
    case analyticCaseLicensePlateEventCreated = "analytic_case_license_plate_event_created"
    case analyticCasePersonCountingEventCreated = "analytic_case_person_counting_event_created"
    case analyticCaseVisitorCountingEventCreated = "analytic_case_visitor_counting_event_created"
    case analyticCaseContainerNumberRecognitionEventCreated = "analytic_case_container_number_recognition_event_created"
}

public enum VMSAppSocketData {
    
    case camerasUpdate(VMSCamerasUpdateSocket)
    case addFavoriteCamera(VMSFavoriteCamerasUpdateSocket)
    case removeFavoriteCamera(VMSFavoriteCamerasUpdateSocket)
    case permissionsUpdate
    case groupsUpdate
    case groupsCreated(VMSCameraGroup)
    case groupsDeleted([Int])
    case cameraGroupsSynced
    case eventCreated(VMSEvent)
    case eventDeleted(VMSEvent)
    case eventUpdated(VMSEvent)
    case analyticEventCreated(VMSEvent)
    case archiveGenerated(VMSArchiveLinkSocket)
    case logout(String?)
}

struct VMSAppPushData: Decodable {
    
    let data: TypeData?
    let subject: String?
    
    struct TypeData: Decodable {
        let type: VMSAppSocketType
        let data: CamerasData?
        let status: StatusType?
        
        enum StatusType: String, Decodable {
            case success = "ok"
            case error
        }
        
        struct CamerasData: Decodable {
            let detached: [Int]?
            let attached: [Int]?
            let id: Int?
            let ids: [Int]?
            let title: String?
            let name: String?
            let from: String?
            let url: String?
            let isIntercom: Bool?
            let download: VMSArchiveLinkSocket.VMSDownloadUrlData?
            let cameraId: Int?
        }
    }
}

struct VMSAppEventPushData: Decodable {
    let data: TypeEventData?
    
    struct TypeEventData: Decodable {
        let data: VMSEvent?
    }
}

public struct VMSCamerasUpdateSocket: Decodable {
    public let detached: [Int]?
    public let attached: [Int]?
}

public struct VMSFavoriteCamerasUpdateSocket: Decodable {
    public let cameraId: Int
}

public struct VMSArchiveLinkSocket: Decodable {
    
    /// Depecated. Will be removed in april 2024 release
    public let url: String?
    public let download: VMSDownloadUrlData?
    
    public struct VMSDownloadUrlData: Decodable {
        public let url: String?
    }
}
