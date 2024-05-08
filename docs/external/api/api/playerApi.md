@toc API/Requests/PlayerApi

# PlayerApi #

Api to use inside player.


## Get live stream

Get camera's live stream of chosen quality.

```
getStream(by cameraId: Int, quality: VMSStream.QualityType, completion: @escaping VMSResultBlock<VMSUrlStringResponse>)

enum QualityType {
    case low
    case high
}
```

`cancelStreamRequest(by cameraId: Int)` - cancel request if you need it


## Get archive stream

Get camera's archive stream url.

If you need to cancel this request use cancelArchiveRequest() method with specified camera id.

```
getArchive(by cameraId: Int, start: Date, completion: @escaping VMSResultBlock<VMSUrlStringResponse>)
```

`start` - a date from which this archive should play

`cancelArchiveRequest(by cameraId: Int)` - cancel request if you need it


## Get url to download archive

Get url to download specific part of camera's archive.

After that you'll receive socket push with `VMSArchiveLinkSocket` object with generated url for downloading.

```
getArchiveLink(cameraId: Int, from: Date, to: Date, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Move camera

Move camera to specific direction.

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


## Move camera to default

Move camera to initial position.

If request was successful response will return `nil`. If any error would occur you would get an `VMSApiError` object.

```
moveCameraHome(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

