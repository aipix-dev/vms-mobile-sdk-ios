@toc API/Requests/PlayerApi

# PlayerApi #

API для использования внутри плеера.


## Получение live потока

Получение live потока с камеры выбранного качества.

```
getStream(by cameraId: Int, quality: VMSStream.QualityType, completion: @escaping VMSResultBlock<VMSUrlStringResponse>)

enum QualityType {
    case low
    case high
}
```

`cancelStreamRequest(by cameraId: Int)` — отменить запрос, если это нужно


## Получение архивного потока

Получение архивного потока с камеры.

Если вам нужно отменить этот запрос, используйте метод `cancelArchiveRequest()` с указанным идентификатором камеры.

```
getArchive(by cameraId: Int, start: Date, completion: @escaping VMSResultBlock<VMSUrlStringResponse>)
```

`start` — дата, с которой этот архив должен воспроизводиться

`cancelArchiveRequest(by cameraId: Int)` — отменить запрос, если это нужно


## Получение ссылки для скачивания архива

Получение URL для загрузки определенной части архива камеры.

После этого вы получите push-уведомление с объектом `VMSArchiveLinkSocket` и сгенерированным URL для загрузки.

```
getArchiveLink(cameraId: Int, from: Date, to: Date, completion: @escaping VMSResultBlock<VMSNoReply>)
```

## Перемещение камеры

Перемещение камеры в определенном направлении.

```
moveCamera(with id: Int, direction: VMSPTZDirection, completion: @escaping VMSResultBlock<VMSNoReply>)

enum VMSPTZDirection {
    case up
    case down
    case left
    case right
    case zoomIn
    case zoomOut
}
```

## Перемещение камеры в положение по умолчанию

Перемещение камеры в исходное положение.

```
moveCameraHome(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

