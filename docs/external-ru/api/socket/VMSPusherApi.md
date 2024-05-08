@toc API/Socket/VMSPusherApi

# VMSPusherApi #
Используется pusher-websocket-swift версии 10.0.1 с некоторыми исправлениями для целей `VMSMobileSDK`.

https://github.com/pusher/pusher-websocket-swift/tree/master

## Инициализация

```
init(baseUrl: String,
    socketUrl: String,
    appKey: String,
    userToken: String,
    userId: Int,
    accessTokenId: String)
```

`baseUrl` — базовый URL для подключения к серверу. Используйте тот же самый, что вы использовали при инициализации VMS

`socketUrl` — специально для предоставленного базового URL, URL сокета для подключения к WebSocket. См. `SocketApi`, чтобы узнать, как получить эту информацию

`appKey` — ключ приложения для подключения к WebSocket. См. `SocketApi`, чтобы узнать, как получить эту информацию

`userToken` — токен текущего пользователя

`userId` — идентификатор текущего пользователя

`accessTokenId` — идентификатор токена доступа текущего пользователя


## VMSSocketManager

Ответ `VMSPusherApi` на протокол `VMSSocketManager`.

`isConnected() -> Bool` — возвращает, подключен сокет или нет

`connect()` — используйте эту функцию для подключения к WebSocket

`disconnect()` — используйте эту функцию для отключения от WebSocket

`getSocketId() -> String?`- получить идентификатор сокетного подключения


## VMSSocketManagerDelegate

`VMSPusherApi` использует `VMSSocketManagerDelegate`.

`changedConnectionState(from old: ConnectionState, to new: ConnectionState)` — реализуйте этот метод для отслеживания изменения статуса соединения

`receivedError(error: PusherError)` — реализуйте этот метод для получения ошибок от pusher

`receivedAppSocket(socket: VMSAppSocketData)` — реализуйте этот метод для получения сокетов `VMSAppSocketType`

`receivedIntercomSocket(socket: VMSIntercomSocketData)` — реализуйте этот метод для получения сокетов `VMSIntercomPushTypes`


## VMSAppSocketData

В случае, если список камер был обновлен для этого пользователя.

```
case camerasUpdate(VMSCamerasUpdateSocket)

struct VMSCamerasUpdateSocket {
    public let detached: [Int]?     /// 
    public let attached: [Int]?     /// 
}
```

`detached` — список идентификаторов камер, которые были удалены из учетной записи этого пользователя

`attached` — список идентификаторов камер, которые были добавлены в учетную запись этого пользователя

В случае, если камера была добавлена или удалена из списка избранных камер.
```
case addFavoriteCamera(VMSFavoriteCamerasUpdateSocket)
case removeFavoriteCamera(VMSFavoriteCamerasUpdateSocket)

struct VMSFavoriteCamerasUpdateSocket: Decodable {
    let cameraId: Int
}
```

В случае, если разрешения пользователя были обновлены.

```
case permissionsUpdate
```

В случае, если группы были обновлены для этого пользователя.

```
case groupsUpdate
```

В случае, если запрос `syncGroups(for cameraId:, groupIds:,complete:)` вернул значение `async` и был успешно выполненным. Для получения более подробной информации см. `GroupApi`.

```
case cameraGroupsSynced
```

В случае удачного манипулирования событиями.

```
case eventCreated(VMSEvent)
case eventDeleted(VMSEvent)
case eventUpdated(VMSEvent)
```

URL для загрузки архива успешно создан.

```
case archiveGenerated(VMSArchiveLinkSocket)

struct VMSArchiveLinkSocket {
    public let download: VMSDownloadUrlData?
    
    public struct VMSDownloadUrlData: Codable {
        public let url: String?
    }
}
```

В случае, если пользователь вышел из системы (например, сеанс был удален).

```
case logout
```

## VMSIntercomPushTypes

В случае, если VOIP-вызов с домофона был отменен с самого домофона.

```
case callCanceled(VMSCanceledCall?)
```

Результаты действий пользователя с домофонами и кодами.

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
