
import Foundation

/// Resposible for creating main entry for working with sockets.
/// Use edited `Pusher` and `NWWebSocket` frameworks
public class VMSPusherApi: VMSSocketManager {
    
    enum SocketEvent {
        static let tokenPushEvent = "App\\Events\\TokenPush"
        static let userPushEvent = "App\\Events\\UserPush"
        static let intercomActivationPushEvent = "Illuminate\\Notifications\\Events\\BroadcastNotificationCreated"
    }
    
    public var pusher: Pusher? = nil
    
    private var socketUrl: VMSSocketUrl
    private var authBuilder: AuthRequestBuilder
    private let userId: Int
    private let accessTokenId: String
    private let appKey: String
    
    public weak var delegate: VMSSocketManagerDelegate?
    
    /// - parameter baseUrl: Should be a string of type `https://example.com`, the exact same was used in `VMSMobileSDK`
    ///
    /// - parameter socketUrl: Should be a string type `wss://example.com:433`, can be received from your server in `getSocketUrl()` method
    ///
    /// - parameter appKey: can be received from your server in `getSocketUrl()` method
    ///
    /// - parameter userToken: can be received when login
    ///
    /// - parameter userId: id of the user
    /// 
    /// - parameter accessTokenId: accessTokenId of the user
    public init(
        baseUrl: String,
        socketUrl: String,
        appKey: String,
        userToken: String,
        userId: Int,
        accessTokenId: String
    ) {
        self.socketUrl = VMSSocketUrl(url: socketUrl)
        self.authBuilder = AuthRequestBuilder(userToken: userToken, urlBuilder: URLBuilderImpl(baseUrl: baseUrl))
        self.userId = userId
        self.accessTokenId = accessTokenId
        self.appKey = appKey
    }
    
    public final func disconnect() {
        pusher?.unsubscribeAll()
        pusher?.disconnect()
    }
    
    public final func isConnected() -> Bool {
        return pusher?.connection.socketConnected ?? false
    }
    
    public final func getSocketId() -> String? {
        return pusher?.connection.socketId
    }
    
    public final func connect() {
        
        guard !socketUrl.url.isEmpty else { return }
        let options = PusherClientOptions(
            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: authBuilder),
            attemptToReturnJSONObject: true,
            autoReconnect: true,
            host: PusherHost.host(socketUrl.url),
            port: socketUrl.port,
            path: socketUrl.path,
            useTLS: socketUrl.encrypted
        )
        
        pusher = Pusher(key: appKey, options: options)
        pusher?.delegate = self
        
        pusher?.bind(eventCallback: { (event) in
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let data: String = event.data,
               let jsonData: Data = data.data(using: .utf8) {
                
                switch event.eventName {
                    
                case SocketEvent.tokenPushEvent:
                    
                    let decoded = try? decoder.decode(VMSAppPushData.self, from: jsonData)
                    
                    if let pushData = decoded, let type = pushData.data?.type {
                        
                        if type == .archiveGenerated {
                            
                            self.delegate?.receivedAppSocket(socket: .archiveGenerated(VMSArchiveLinkSocket(url: pushData.data?.data?.url, download: pushData.data?.data?.download)))
                            
                        } else {
                            self.delegate?.receivedAppSocket(socket: .logout(pushData.subject))
                        }
                        
                    }
                case SocketEvent.intercomActivationPushEvent:
                    
                    if let pushData = try? decoder.decode(VMSIntercomPushData.self, from: jsonData)  {
                        
                        switch pushData.type {
                            
                        case .store:
                            self.delegate?.receivedIntercomSocket(socket: .intercomStored(pushData.intercom))
                        case .delete:
                            self.delegate?.receivedIntercomSocket(socket: .intercomsDeleted(VMSIntercomDeleteSocket(deletedIds: pushData.deletedIds)))
                        case .rename:
                            self.delegate?.receivedIntercomSocket(socket: .intercomRenamed(pushData.intercom))
                        case .update:
                            self.delegate?.receivedIntercomSocket(socket: .intercomUpdated(pushData.intercom))
                        case .keyConfirmed:
                            self.delegate?.receivedIntercomSocket(socket: .intercomKeyConfirmed(pushData.intercom))
                        case .keyError:
                            self.delegate?.receivedIntercomSocket(socket: .intercomKeyError(VMSIntercomErrorSocket(error: pushData.error)))
                        case .addError:
                            self.delegate?.receivedIntercomSocket(socket: .intercomAddError(VMSIntercomErrorSocket(error: pushData.error)))
                        case .codeStore:
                            self.delegate?.receivedIntercomSocket(socket: .intercomCodeStored(pushData.intercomCode))
                        case .codeDelete:
                            self.delegate?.receivedIntercomSocket(socket: .intercomCodesDeleted(VMSIntercomDeleteSocket.init(deletedIds: pushData.deletedIds)))
                        case .callStore:
                            self.delegate?.receivedIntercomSocket(socket: .intercomCallStored(pushData.intercomCall))
                        case .callDelete:
                            self.delegate?.receivedIntercomSocket(socket: .intercomCallsDeleted(VMSIntercomDeleteSocket.init(deletedIds: pushData.deletedIds)))
                        case .cancelCall:
                            self.delegate?.receivedIntercomSocket(socket: .intercomCallCanceled(pushData.data))
                        default: break
                        }
                    }
                    
                case SocketEvent.userPushEvent:
                    
                    let decoded = try? decoder.decode(VMSAppPushData.self, from: jsonData)
                    
                    if let pushData = decoded, let type = pushData.data?.type {
                        
                        switch type {
                            
                        case VMSAppSocketType.camerasUpdate:
                            
                            self.delegate?.receivedAppSocket(socket: VMSAppSocketData.camerasUpdate(VMSCamerasUpdateSocket(detached: pushData.data?.data?.detached, attached: pushData.data?.data?.attached)))
                            
                        case .favoriteCamera:
                            
                            if let cameraId = pushData.data?.data?.cameraId {
                                self.delegate?.receivedAppSocket(socket: .addFavoriteCamera(VMSFavoriteCamerasUpdateSocket.init(cameraId: cameraId)))
                            }
                            
                        case .removeFavoriteCamera:
                            
                            if let cameraId = pushData.data?.data?.cameraId {
                                self.delegate?.receivedAppSocket(socket: .removeFavoriteCamera(VMSFavoriteCamerasUpdateSocket.init(cameraId: cameraId)))
                            }
                            
                        case .cameraGroupsSynced:
                            self.delegate?.receivedAppSocket(socket: .cameraGroupsSynced)
                            
                        case .groupsUpdate:
                            self.delegate?.receivedAppSocket(socket: .groupsUpdate)
                        case .groupsCreated:
                            if let pushData = pushData.data?.data, let id = pushData.id {
                                let cameraGroup = VMSCameraGroup(id: id, name: pushData.name)
                                self.delegate?.receivedAppSocket(socket: .groupsCreated(cameraGroup))
                                break
                            }
                            self.delegate?.receivedAppSocket(socket: .groupsUpdate)
                        case .groupsDeleted:
                            if let pushData = pushData.data?.data, let ids = pushData.ids {
                                self.delegate?.receivedAppSocket(socket: .groupsDeleted(ids))
                                break
                            }
                            self.delegate?.receivedAppSocket(socket: .groupsUpdate)
                        case .permissionsUpdate:
                            self.delegate?.receivedAppSocket(socket: .permissionsUpdate)
                            
                        case .analyticCaseFaceEventCreated, .analyticCaseLoudSoundEventCreated, .analyticCaseLicensePlateEventCreated, .analyticCaseLineIntersectionEventCreated, .analyticCaseMotionDetectEventCreated, .analyticCasePersonCountingEventCreated, .analyticCaseSmokeFireEventCreated, .analyticCaseVisitorCountingEventCreated, .analyticCaseCameraObstacleEventCreated, .analyticCaseContainerNumberRecognitionEventCreated:
                            
                            if let intercomData = try? decoder.decode(VMSAppEventPushData.self, from: jsonData) {
                                let event = intercomData.data?.data
                                event?.analyticFile?.editPreviewUrl(baseUrl: self.authBuilder.urlBuilder.getBaseUrl())
                                
                                if pushData.data?.data?.isIntercom == true {
                                    
                                    self.delegate?.receivedIntercomSocket(socket: .intercomEventStored(event))
                                    
                                } else if let event {
                                    
                                    self.delegate?.receivedAppSocket(socket: .analyticEventCreated(event))
                                }
                            }
                            
                        case .markCreated, .markDeleted, .markUpdated:
                            
                            if let markDecoded = try? decoder.decode(VMSAppEventPushData.self, from: jsonData), let event = markDecoded.data?.data {
                                
                                if type == .markCreated {
                                    self.delegate?.receivedAppSocket(socket: .eventCreated(event))
                                } else if type == .markDeleted {
                                    self.delegate?.receivedAppSocket(socket: .eventDeleted(event))
                                } else if type == .markUpdated {
                                    self.delegate?.receivedAppSocket(socket: .eventUpdated(event))
                                } else {
                                    self.delegate?.receivedAppSocket(socket: .analyticEventCreated(event))
                                }
                            }
                        default: break
                        }
                    }
                default: break
                }
            }
        })
        pusher?.connect()
        
        let _ = pusher?.subscribe("private-token.\(accessTokenId)")
        let _ = pusher?.subscribe("private-user.\(userId)")
    }
}

extension VMSPusherApi: PusherDelegate {
    
    public func debugLog(message: String) {
        self.delegate?.receivedInfo(message: message)
    }
    
    public func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        self.delegate?.changedConnectionState(from: old, to: new)
    }
    
    public func receivedError(error: PusherError) {
        self.delegate?.receivedError(error: error)
    }
    
    public func subscribedToChannel(name: String) {
        self.delegate?.receivedInfo(message: "Subscribed to channel: \(name)")
    }
    
    public func subscribedToChannelNoDataInPayload(name: String) {
        self.delegate?.receivedInfo(message: "Subscribed to channel: \(name)")
    }
    
    public func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        self.delegate?.receivedInfo(message: "Failed to subscribe to channel: \(name), data: \(data ?? ""), error: \(error?.localizedDescription ?? "")")
    }
}

class AuthRequestBuilder: AuthRequestBuilderProtocol {
    
    var userToken: String
    var urlBuilder: URLBuilder
    
    init(userToken: String, urlBuilder: URLBuilder) {
        self.userToken = userToken
        self.urlBuilder = urlBuilder
    }
    
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        
        var request = URLRequest(url: URL(string: urlBuilder.build(path: ApiPaths.Socket.BroadcastingAuth))!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channelName)".data(using: String.Encoding.utf8)
        request.addValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        
        return request
    }
}
