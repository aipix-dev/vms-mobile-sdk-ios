
import Foundation

struct ApiPaths {
    
    struct Authorization {
        static let Token = "token" // POST
        static let Logout = "logout" // POST
        static let Captcha = "captcha" // GET
    }

    static let Static = "static" // GET
    static let BasicStatic = "static/basic" // GET
    static let Dictionary = "dictionary"
    static let Devices = "devices"
    
    static let UserSelf = "users/self" // GET
    
    struct Socket {
        
        static let BroadcastingAuth = "broadcasting/auth" // For Sockets
        static let WsUrl = "wsurl" // GET
    }
    
    struct Cameras {
        
        static let Favorites = "cameras/favorites" // GET
        static let FlatTree = "cameras/flat-tree" // GET
        static let Groups = "groups" // GET // or POST for creating new group // PUT for rename
        static let List = "cameras"
        
        static func crudFavorites(id: Int) -> String {
            return List + "/\(id)/favorites"
        }
        
        static func streams(id: Int) -> String {
            return List + "/\(id)/streams"
        }
        
        static func archive(id: Int) -> String {
            return List + "/\(id)/streams/archive"
        }
        
        static func preview(id: Int) -> String {
            return List + "/\(id)/preview"
        }
        
        static func archiveLink(id: Int) -> String {
            return List + "/\(id)/archive/link"
        }
        
        static func rename(id: Int) -> String {
            return List + "/\(id)/rename"
        }
        
        static func issue(issueId: Int, cameraId: Int) -> String {
            return "issues/\(issueId)/cameras/\(cameraId)"
        }
        
        static func info(id: Int) -> String{
            return List + "/\(id)"
        }
        
        static func move(id: Int) -> String {
            return List + "/\(id)/move"
        }
        
        static func moveHome(id: Int) -> String {
            return List + "/\(id)/move/home"
        }
        
        static func marks(id: Int) -> String {
            return List + "/\(id)/marks"
        }
        
        static func accessMark(id: Int, bookmarkId: Int) -> String { // DELETE, PUT
            return List + "/\(id)/marks/\(bookmarkId)"
        }
        
        static func nearestMark(id: Int) -> String {
            return List + "/\(id)/marks/rewind"
        }
        
        static func accessGroup(groupId: Int) -> String { // PUT
            return Groups + "/\(groupId)"
        }
        
        static func groupsSync(id: Int) -> String {
            return List + "/\(id)/sync-groups"
        }
    }
    
    struct Intercom {
        
        static let List = "intercom"
        static let Codes = "intercom/codes"
        static let Events = "intercom/events"
        static let Calls = "intercom/calls"
        
        static func flat(id: Int) -> String {
            return List + "/\(id)/flat"
        }
        
        static func patch(id: Int) -> String {
            return List + "/\(id)"
        }
        
        static func openDoor(id: Int) -> String {
            return List + "/\(id)/open-door"
        }
        
        static func code(id: Int) -> String {
            return List + "/\(id)/codes"
        }
        
        static func intercomAnalyticFile(id: Int) -> String {
            return List + "/\(id)/files" // GET, POST, DELETE
        }
        
        static func updateAnalyticFile(intercomId: Int, fileId: Int) -> String {
            return List + "/\(intercomId)/files/\(fileId)" // POST
        }
    }
    
    struct Sessions {
        
        static let List = "sessions" // GET
        
        static func delete(id: String) -> String {
            return List + "/\(id)" // POST
        }
    }
    
    struct Calls {
        
        static func status(id: Int) -> String {
            return Intercom.Calls + "/\(id)"
        }
        
        static func answer(id: Int) -> String {
            return Intercom.Calls + "/\(id)/start"
        }
        
        static func cancel(id: Int) -> String {
            return Intercom.Calls + "/\(id)/cancel"
        }
        
        static func end(id: Int) -> String {
            return Intercom.Calls + "/\(id)/end"
        }
    }
    
    struct Events {
        
        static let Marks = "marks" // GET
        static let Events = "events" // GET
        static let AnalyticsEvents = "analytic-case/events" // GET
        static let AnalyticsCases = "analytic-case" // GET
        
    }
    
    struct Bridge {
        
        static let List = "bridges" // GET
        
        static func update(id: Int) -> String {
            return List + "/\(id)"
        }
        
        static func cameras(id: Int) -> String {
            return List + "/\(id)/cameras/connected"
        }
        
        static func deleteCamera(bridgeId: Int, cameraId: Int) -> String {
            return List + "/\(bridgeId)/cameras/\(cameraId)"
        }
    }
}
