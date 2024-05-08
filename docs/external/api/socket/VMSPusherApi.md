@toc API/Socket/VMSPusherApi

# VMSPusherApi #

Uses pusher-websocket-swift of 10.0.1 version with some fixes for `VMSMobileSDK` purposes.

https://github.com/pusher/pusher-websocket-swift/tree/master

## Initialization

```
init(baseUrl: String,
    socketUrl: String,
    appKey: String,
    userToken: String,
    userId: Int,
    accessTokenId: String)
```

`baseUrl` - base url to connect with the server. Use the same you used in VMS initialization

`socketUrl` - specific for provided base url, socket url to connect to WebSocket. See `SocketApi` to know how to get this info

`appKey` - app key to connect to WebSocket. See `SocketApi` to know how to get this info

`userToken` - token of current user

`userId` - id of current user

`accessTokenId` - access token id of current user


## VMSSocketManager

`VMSPusherApi` response to `VMSSocketManager` protocol

`isConnected() -> Bool` - returns if socket connected or not

`connect()` - use this function to connect to WebSocket

`disconnect()` - use this function to disconnect from WebSocket

`getSocketId() -> String?`- get socket identificator of your connection


## VMSSocketManagerDelegate

`VMSPusherApi` uses `VMSSocketManagerDelegate`

`changedConnectionState(from old: ConnectionState, to new: ConnectionState)` - implement this method to track changing of connection status

`receivedError(error: PusherError)` - implement this method to receive errors from pusher

`receivedAppSocket(socket: VMSAppSocketData)` - implement this method to receive sockets of `VMSAppSocketType`

`receivedIntercomSocket(socket: VMSIntercomSocketData)` - implement this method to receive sockets of `VMSIntercomPushTypes`


## VMSAppSocketData

In case list of cameras was updated for this user

```
case camerasUpdate(VMSCamerasUpdateSocket)

struct VMSCamerasUpdateSocket {
    public let detached: [Int]?     /// 
    public let attached: [Int]?     /// 
}
```

`detached` - list of cameras ids that were deleted from this user's account

`attached` - list of cameras ids that were added to this user's account

In case camera was added or removed from favorite list.
```
case addFavoriteCamera(VMSFavoriteCamerasUpdateSocket)
case removeFavoriteCamera(VMSFavoriteCamerasUpdateSocket)

struct VMSFavoriteCamerasUpdateSocket: Decodable {
    let cameraId: Int
}
```

In case user's permissions were updated
```
case permissionsUpdate
```

In case groups were updated for this user
```
case groupsUpdate
```

In case request `syncGroups(for cameraId:, groupIds:, completion:)` returned `async` value and was successful and done. See `GroupApi` for more details.
```
case cameraGroupsSynced
```

In case of successful manipulating with events.
```
case eventCreated(VMSEvent)
case eventDeleted(VMSEvent)
case eventUpdated(VMSEvent)
```

Archive download url was generated successfully.
```
case archiveGenerated(VMSArchiveLinkSocket)

struct VMSArchiveLinkSocket {
    public let download: VMSDownloadUrlData?
    
    public struct VMSDownloadUrlData: Codable {
        public let url: String?
    }
}
```

In case user was logged out from system (ex. the session was deleted)
```
case logout
```

## VMSIntercomPushTypes

In case VOIP call from intercom was canceled from intercom.
```
case callCanceled(VMSCanceledCall?)
```

Results of user's actions with intercoms and codes.
```
case intercomCodeStored(VMSIntercomCode?)
case intercomCallStored(VMSIntercomCall?)
case intercomStored(VMSIntercom?)
case intercomEventStored(VMSEvent?)
case intercomKeyConfirmed(VMSIntercom?)
case intercomRenamed(VMSIntercom?)
case intercomsDeleted(VMSIntercomDeleteSocket?)
case intercomCodesDeleted(VMSIntercomDeleteSocket?)
case callsDeleted(VMSIntercomDeleteSocket?)
case intercomKeyError(VMSIntercomErrorSocket?)
case intercomAddError(VMSIntercomErrorSocket?)
```
