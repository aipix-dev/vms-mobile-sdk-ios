@toc API/Requests/Cameras/CameraEventsApi

# CameraEventsApi #

API для работы с событиями внутри плеера.


## Получение всех событий

Получить все события камеры за определенный период времени и определенные типы событий. 

См. `StaticsApi`, чтобы получить все возможные типы событий. 

Если типы не указаны, сервер будет возвращать события всех возможных типов.

```
getCameraEvents(with cameraId: Int, from: Date, to: Date, types: [String]?, completion: @escaping VMSResultBlock<[VMSEvent]>)
```


## Получение ближайшего события

Получить ближайшее или предыдущее событие от текущей даты в архиве камеры. 

См. `StaticsApi`, чтобы получить все возможные типы событий.

Если типы не указаны, сервер будет возвращать события всех возможных типов.

```
getNearestEvent(with cameraId: Int, from date: Date, types: [String]?, direction: VMSRewindDirection, completion: @escaping VMSResultBlock<VMSRewindEventResponse>)

public enum VMSRewindDirection: String {
    case next
    case previous
}

public struct VMSRewindEventResponse: Decodable {
    public let mark: VMSEvent?
}
```

## Создание события

Создать новое событие

```
createEvent(cameraId: Int, eventName: String, from: Date, completion: @escaping VMSResultBlock<VMSEvent>)
```

## Обновление события

Обновить данные уже существующего события

```
updateEvent(with id: Int, cameraId: Int, eventName: String, from: Date, completion: @escaping VMSResultBlock<VMSEvent>)
```

## Удаление события

Удалить существующее событие

```
deleteEvent(with id: Int, cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```
