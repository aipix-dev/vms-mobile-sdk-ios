@toc API/Requests/EventsListApi

# EventsListApi #

Api to get all user's events.


## Get cameras with analytics

Get list of cameras by page and search if needed where user has analytics on.

```
getCamerasWithAnalytics(page: Int, search: String?, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
```

## Events

### Get mark events

Get the list of mark events.

```
getEventsMarks(page: Int, request: VMSEventsRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
```

### Get system events

Get the list of system events.

```
getEventsSystem(page: Int, request: VMSEventsRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
```

### Get analytic events

Get the list of analytic events.

```
getEventsAnalytic(page: Int, request: VMSEventsAnalyticRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
```

### Get analytics cases

Get all cases of specific analytic cases types. See `StaticsApi` to get all available analytic cases types.

```
getEventsAnalyticCases(page: Int, analyticCasesTypes: [String], completion: @escaping  VMSResultBlock<PaginatedResponse<VMSAnalyticCase>>)
```

### Information you need to make requests to get events

```
public struct VMSEventsRequest {
    public let cameraIds: [Int]
    public let types: [String]
    public let sortDirection: VMSSortDirection
    public let timePeriod: VMSEventTimePeriod?
}
```

`types` - if you want to get marks then send marks types. In case you want to get events list sent here event types. See `StaticsApi` for more details

`timePeriod` - time period from which you want to take events from. Can be `specific` or `setManualy`, in case of `setManualy` set `from` and `to` dates respectively

```
public struct VMSEventsAnalyticRequest {
    public let eventNames: [String]
    public let caseIds: [Int]
    public let cameraIds: [Int]
    public let analyticEventTypes: [String]
    public let sortDirection: VMSSortDirection
    public let timePeriod: VMSEventTimePeriod?
}
```

`analyticEventTypes` - analytics event types. See `StaticsApi` for more details

`eventNames` - event name you get from `availableEvents` of `VMSAnalyticCase` object

`timePeriod` - time period from which you want to take events from. Can be `specific` or `setManualy`, in case of `setManualy` set `from` and `to` dates respectively

```
public enum VMSSortDirection: String {
    case ascending = "asc"
    case descending = "desc"
}
```


