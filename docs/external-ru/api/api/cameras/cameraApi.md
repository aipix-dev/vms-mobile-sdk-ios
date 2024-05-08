@toc API/Requests/Cameras/CameraApi

# CameraApi #

API для получения информации о камерах.


## Получение главного дерева

Получить все камеры, которые есть у пользователя.

```
getCamerasTree(search: String?, completion: @escaping VMSResultBlock<[VMSCameraTree]>)
```

## Поиск камеры

Получить список камер по запросу.

```
getSearchCameras(search: String, completion: @escaping VMSResultBlock<[VMSCamera]>)
```

`cancelSearchCamerasRequest()` — отменить запрос, если это необходимо

## Получение камеры

Получить конкретную информацию о камере по идентификатору камеры.

```
getCamera(with cameraId: Int, completion: @escaping VMSResultBlock<VMSCamera>)
```
`cancelCameraInfoRequest(with cameraId: Int)` — отменить запрос, если это необходимо


## Переименование камеры

Переименовать камеру по ее идентификатору и новому имени.

```
renameCamera(with id: Int, name: String, completion: @escaping VMSResultBlock<VMSCamera>)
```


## Отправить жалобу

Отправить жалобу, если с камерой что-то не так. См. `StaticsApi`, чтобы получить список возможных проблем.

```
sendReport(info: VMSReportRequest, completion: @escaping VMSResultBlock<VMSNoReply>)
```

### VMSReportRequest

Объект с необходимой информацией для отправки отчета.

```
init(issueId: Int, cameraId: Int)
```

`issueId` — идентификатор сообщенной проблемы. Больше информации см. в `StaticsApi`

`cameraId` — идентификатор камеры с проблемой


## Получение ссылки для скачивания превью камеры

Получить ссылку на превью камеры на конкретную дату. Вы получите ссылку, с которой можно скачать .mp4 файл с одним кадром с камеры.

Если в запросе отсутствует параметр `date`, вы получите ссылку на последний актуальный кадр.

```
getCameraPreviewURL(with cameraId: Int, date: String?, completion: @escaping VMSResultBlock<VMSCameraPreviewResponse>)
```

`cancelCameraPreviewURLRequest(with cameraId: Int)` — отменить запрос, если это необходимо


## Скачать превью камеры

Скачать .mp4 файл локально, чтобы потом его сконверировать в изображение.

Если запрос прошел успешно, вы получите локальный URL, где был сохранён файл. Если произойдет какая-либо ошибка, вы получите объект `Error`.

```
downloadCameraPreviewFile(url: URL, destinationUrl: URL, completionHandler: @escaping ((URL?, Error?) -> Void))
```

`cancelDownloadCameraPreviewRequest(url: URL)` — отменить запрос, если это необходимо
