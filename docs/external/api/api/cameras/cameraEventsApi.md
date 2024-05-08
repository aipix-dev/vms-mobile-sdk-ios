@toc API/Requests/Cameras/CameraEventsApi

# CameraEventsApi #

Api to get work with events inside player.


## Get all events

Get all camera events in specific period of time ad specific event types.

See `StaticsApi` to get all possible event types.

If no types specified server will return events of all possible types.

```
getCameraEvents(with cameraId: Int, from: Date, to: Date, types: [String]?, completion: @escaping VMSResultBlock<[VMSEvent]>)
```


## Get the nearest event

Get the nearest event next or previous from your current date in camera archive.

See `StatisticsApi` to get all possible event types.

If no types specified server will return events of all possible types.

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

## Create event

Create new event.

```
createEvent(cameraId: Int, eventName: String, from: Date, completion: @escaping VMSResultBlock<VMSEvent>)
```

## Update event

Update existing event.

```
updateEvent(with id: Int, cameraId: Int, eventName: String, from: Date, completion: @escaping VMSResultBlock<VMSEvent>)
```

## Delete event

Delete existing event.

```
deleteEvent(with id: Int, cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```
