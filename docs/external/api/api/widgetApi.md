@toc API/Requests/WidgetApi

# WidgetApi #

Api to get information from server for device widgets.


## Get list of cameras

Get the list of detailed information about cameras of given ids.

```
getWidgetCameras(ids: [String], completion: @escaping VMSResultBlock<[VMSWidgetCamera]>)
```


## Get camera preview

Get camera preview. You will receive .mp4 file of camera one frame.

```
getWidgetCameraPreviewURL(cameraId: Int, completion: @escaping VMSResultBlock<VMSCameraPreviewResponse>)
```

`cancelCameraPreviewURLRequest(with cameraId: Int)` - cancel request if you need it


## Get list of intercoms

Get the list of detailed information about intercoms of given ids.

```
getWidgetIntercoms(ids: [String], completion: @escaping VMSResultBlock<[VMSWidgetIntercom]>)
```


