@toc API/Requests/Cameras/CameraApi

# CameraApi #

Api to get cameras information.


## Get main tree

Get all cameras user has.

```
getCamerasTree(search: String?, completion: @escaping VMSResultBlock<[VMSCameraTree]>)
```


## Camera search

Get the list of cameras according to search.

```
getSearchCameras(search: String, completion: @escaping VMSResultBlock<[VMSCamera]>)
```

`cancelSearchCamerasRequest()` - cancel request in case you need it


## Get camera

Get specific camera information by camera's id.

```
getCamera(with cameraId: Int, completion: @escaping VMSResultBlock<VMSCamera>)
```
`cancelCameraInfoRequest(with cameraId: Int)` - cancel request in case you need it


## Rename camera

Rename camera by it's id and with it's new name.

If request was successful you'll get updated `VMSCamera` object.

```
renameCamera(with id: Int, name: String, completion: @escaping VMSResultBlock<VMSCamera>)
```


## Send report

Send report if something is wrong with the camera. See `StaticsApi` to get the list of possible issues.

```
sendReport(info: VMSReportRequest, completion: @escaping VMSResultBlock<VMSNoReply>)
```

### VMSReportRequest

Object with needed info to send report.

```
init(issueId: Int, cameraId: Int)
```

`issueId` - id of reported issue. See `StaticsApi` for more information

`cameraId` - id of camera with issue


## Get camera preview url

Get camera preview of specific date. You will receive an url from which you can download .mp4 file of camera one frame.

If there is no parameter `date` provided you'll receive the last frame.

```
getCameraPreviewURL(with cameraId: Int, date: String?, completion: @escaping VMSResultBlock<VMSCameraPreviewResponse>)
```

`cancelCameraPreviewURLRequest(with cameraId: Int)` - cancel request in case you need it


## Download camera preview

Download .mp4 file locally in order to be able to convert it to image.

If request was successful you'll get a local url where the file was saved. If any error would occur you would get an `Error` object.

```
downloadCameraPreviewFile(url: URL, destinationUrl: URL, completionHandler: @escaping ((URL?, Error?) -> Void))
```

`cancelDownloadCameraPreviewRequest(url: URL)` - cancel download request in case you need it
