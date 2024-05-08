@toc API/Requests/User/SessionsApi

# SessionsApi #

Api to manipulate different users sessions.

## Get sessions list

Get the list of different sessions.

```
getSessionsList(completion: @escaping VMSResultBlock<[VMSSession]>)
```


## Delete session

Delete specific session of a given id.

```
deleteSession(with id: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```
