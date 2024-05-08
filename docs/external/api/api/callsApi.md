@toc API/Requests/CallsApi

# CallsApi #

Api to work with voip calls from intercom.


## Get call status

Use this request to check current call status.

```
callStatus(with callId: Int, completion: @escaping VMSResultBlock<VMSIntercomCall>)
```


## Call answered

Use this request to let server know that the call was answered on current device.

```
callAnswered(callId: Int, completion: @escaping VMSResultBlock<VMSVoipCall>)
```


## Call canceled

Use this request to let server know that the call was canceled on current device.

```
callCanceled(callId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Call ended

Use this request to let server know that the call was ended on current device.

```
callEnded(callId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

