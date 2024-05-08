@toc API/Requests/Cameras/GroupApi

# GroupApi #

Api to manipulate with camera groups.


## Get group list

Get list of camera groups. Specify page for request. For the first request set `page = 0`.

```
getGroupsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCameraGroup>>)
```


## Create group

Create new group of cameras with specified name. Initially the group is empty.

```
createGroup(with name: String, completion: @escaping VMSResultBlock<VMSCameraGroup>)
```


## Rename group

Rename specific group by it's id with new name.

```
renameGroup(with id: Int, newName: String, completion: @escaping VMSResultBlock<VMSCameraGroup>)
```


## Delete group

Delete specific group by it's id.

```
deleteGroup(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Update group

Update group with specified information.

```
updateGroup(info: VMSUpdateGroupRequest, completion: @escaping VMSResultBlock<VMSCameraGroup>)
```

### VMSUpdateGroupRequest

Object with needed information to update a group

```
init(groupName: String, groupId: Int, cameraIds: [Int])
```

`groupName` - new name of the group. If you don't' want to change group name set old name in this parameter

`groupId` - id of the group to specify needed group

`cameraIds` -  list of cameras ids you want to add to this group


## Sync groups

This request will sync specified camera with all user's groups. The request require a list of groups where this camera will belong to. Camera will be deleted from other groups.

```
syncGroups(for cameraId: Int, groupIds: [Int], completion: @escaping VMSResultBlock<VMSTypeGroupResponse>)
```

`cameraId` - specify camera by it's id

`groupIds` - specify the list of group ids where camera will be presented (camera will be added to a group if it wasn't there before)

### VMSGroupSyncType

Information about the way of syncing on server side.

```
enum VMSGroupSyncType: String, Codable {
    case sync
    case async
}
```
`sync` - if the syncing was done

`async` - if user has more than 50 group the backend request will run asynchronous.

After process is done you'll receive socket message you can handle. See `VMSPusherApi` for more details
