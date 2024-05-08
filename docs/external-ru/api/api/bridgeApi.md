@toc API/Requests/BridgeApi

# BridgeApi #

API для управления устройствами клиент.


## Получение списка устройств

Получение списка устройств клиента. Укажите страницу для запроса. Для первого запроса установите `page = 0`.

```
getBridgesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSBridge>>)
```


## Добавление устройства

Используйте этот запрос, чтобы добавить устройство клиента в систему.

```
createBridge(request: VMSBridgeCreateRequest, completion: @escaping VMSResultBlock<VMSBridge>)
```

### VMSBridgeCreateRequest

```
struct VMSBridgeCreateRequest {
    let name: String
    let mac: String?
    let serialNumber: String?
}
```

`name` - название устройства

`mac` - mac-адрес устройства. Обязателен, если отсутствует серийный номер устройства

`serialNumber` - серийный номер устройства. Обязателен, если отсутствует mac-адрес устройства



## Переименование устройства

Используйте этот запрос, чтобы установить новое название устройства.

```
updateBridge(with id: Int, name: String, completion: @escaping VMSResultBlock<VMSBridge>)
```


## Детали устройства

Используйте этот запрос, чтобы получить более детальную информацию об устройстве.

```
getBridge(with id: Int, completion: @escaping VMSResultBlock<VMSBridge>)
```

## Получение списка камер устройства

Получение списка камер устройства клиента. Укажите страницу для запроса. Для первого запроса установите `page = 0`.

```
getBridgeCameras(bridgeId: Int, page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
```

## Удалить камеру с устройства

Используйте этот запрос, чтобы удалить камеру с устройства клиента.

```
deleteBridgeCamera(with bridgeId: Int, cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```


