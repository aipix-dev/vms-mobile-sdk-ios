@toc API/Requests/BridgeApi

# BridgeApi #

Api to work with bridges.


## Get bridges list

Get list of bridges. Specify page for request. For the first request set `page = 0`.

```
getBridgesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSBridge>>)
```


## Create bridge

Use this request to create bridge.

```
createBridge(request: VMSBridgeCreateRequest, completion: @escaping VMSResultBlock<VMSBridge>)
```

### VMSBridgeCreateRequest

```
struct VMSBridgeCreateRequest {
    let name: String
    let mac: String?
    let serialNumber: String?
}
```

`name` - name of bridge

`mac` - mac-address of bridge. Required if there is no serial number

`serialNumber` - serial number of bridge. Required if there is no mac-address



## Rename bridge

Use this request to set new name for a bridge.

```
updateBridge(with id: Int, name: String, completion: @escaping VMSResultBlock<VMSBridge>)
```


## Bridge details

Use this request to get detailed information about bridge.

```
getBridge(with id: Int, completion: @escaping VMSResultBlock<VMSBridge>)
```

## Get bridge cameras list

Get list of bridge cameras. Specify page for request. For the first request set `page = 0`.

```
getBridgeCameras(bridgeId: Int, page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
```

## Delete bridge camera

Use this request to delete bridge camera.

```
deleteBridgeCamera(with bridgeId: Int, cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```


