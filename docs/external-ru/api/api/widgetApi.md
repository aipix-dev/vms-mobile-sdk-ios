@toc API/Requests/WidgetApi

# WidgetApi #

API для получения информации с сервера для виджетов устройства.

## Получение списка камер

Получение списка подробной информации о камерах с заданными идентификаторами.

```
getWidgetCameras(ids: [String], completion: @escaping VMSResultBlock<[VMSWidgetCamera]>)
```


## Получение превью камеры

Получение превью камеры. Вы получите файл в формате .mp4 с одним кадром с камеры.

```
getWidgetCameraPreviewURL(cameraId: Int, completion: @escaping VMSResultBlock<VMSCameraPreviewResponse>)
```

`cancelCameraPreviewURLRequest(with cameraId: Int)` - отмените запрос, если это необходимо, по иденификаору камеры


## Получение списка домофонов

Получение списка подробной информации о домофонах заданных идентификаторов.

```
getWidgetIntercoms(ids: [String], completion: @escaping VMSResultBlock<[VMSWidgetIntercom]>)
```


