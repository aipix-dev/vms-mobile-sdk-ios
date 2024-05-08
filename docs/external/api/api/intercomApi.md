@toc API/Requests/IntercomApi

# IntercomApi #

Api to manipulate with intercoms.


## Get intercoms list

Get list of intercoms. Specify page for request. For the first request set `page = 0`.

```
getIntercomsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercom>>)
```


## Get intercom codes list

Get list of intercom codes. Specify page for request. For the first request set `page = 0`.

```
getIntercomCodesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercomCode>>)
```

## Get intercom face recognition analytic events list

Get list of intercom analytic events. Specify page for request. For the first request set `page = 0`.

```
func getIntercomEventsList(page: Int, request: VMSIntercomFaceRecognitionRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
```

Additionaly you can add filtration to your request.

```
struct VMSIntercomFaceRecognitionRequest {

    public let timePeriod: VMSEventTimePeriod?
}
```


## Get intercom calls list

Get list of intercom calls. Specify page for request. For the first request set `page = 0`.

```
getIntercomCallsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercomCall>>)
```


## Start adding intercom flow

This request is used to start adding intercom flow.

User should enter a code received from this request and then apply physical intercom key to the intercom.

After that you will receive socket push and user should enter a flat number.

If this intercom was already added, this request will return error with appropriate informational message.

```
getActivateCode(completion: @escaping VMSResultBlock<VMSActivationCode>)
```


## Set flat number

Connect intercom with specific flat number.

Create new group of cameras with specified name. Initially the group is empty.

```
setIntercomFlat(intercomId: Int, flat: Int, completion: @escaping VMSResultBlock<VMSIntercom>)
```


## Rename intercom

Rename specific intercom by it's id with new name.

```
renameIntercom(with id: Int, newName: String, completion: @escaping VMSResultBlock<VMSIntercom>)
```


## Set intercom settings

Change settings parameters for specific intercom by it's id.

```
changeIntercomSettings(with id: Int, isEnabled: Bool, timetable: VMSTimetable?, completion: @escaping VMSResultBlock<VMSIntercom>)

public final class VMSTimetable: Codable {
    public var days: [VMSDays]?
    public var intervals: [VMSIntervals]?
}
```

`id` - id of intercom

`isEnabled` - set to `false` if you want to disable intercom. In this case calls from intercom won't be received to current device

`timetable` - intercom calls schedule. Calls will be received only according to chosen time

### VMSTimetable

Intercom calls schedule.

Timetable can be set in two ways:

- by days
- by intervals

You cannot set both parameters simultaneously. In this case intervals will be set.

```
init(days: [VMSDays]?, intervals: [VMSIntervals]?)
```


## Open door

Open intercom's door.

```
openDoor(intercomId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Create code

Create code to open the door physically.

```
createCode(intercomId: Int, name: String, expiredAt: Date, completion: @escaping VMSResultBlock<VMSIntercomCode>)
```

`intercomId` - id of intercom

`name` - the name for new code

`expiredAt` - date till which this code will be valid


## Delete intercoms

Delete intercoms you don't need anymore.

```
deleteIntercoms(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Delete intercom codes

Delete intercom codes you don't need anymore.

```
deleteIntercomCodes(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Delete calls

Delete calls you don't need anymore.

```
deleteCalls(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Create intercom face recogition analytic resource file

For intercom there is an analytic case to create an event when a face recognition happens. For that at first there need to be a resource file created.

```
func createFaceRecognitionAnalyticFile(intercomId: Int, request: VMSIntercomFaceRecognitionResourceRequest, completion: @escaping VMSResultBlock<VMSAnalyticFile>)
```

### VMSIntercomFaceRecognitionResourceRequest

```
struct VMSIntercomFaceRecognitionResourceRequest {
    
    public let name: String
    public let image: Data
    
    init(name: String, image: Data)
}
```

`name` - name of the resource

`image` - image data that should be uploaded, max size to upload - 5MB


## Update intercom analytic resource file name

Update resource file name.

```
func updateIntercomAnalyticFileName(intercomId: Int, fileId: Int, name: String, completion: @escaping VMSResultBlock<VMSAnalyticFile>)
```

## Delete intercom analytic resource file

Delete intercom analytic resource file.

```
func deleteIntercomAnalyticFile(intercomId: Int, fileId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

## Get the list of intercom analytic resource file

Get the list of intercom analytic resource file. Specify page for request. For the first request set `page = 0`.

```
func getIntercomAnalyticFiles(page: Int, intercomId: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSAnalyticFile>>)
```
