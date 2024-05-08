@toc API/Requests/CallsApi

# CallsApi #

API для работы с VoIP звонками с домофона.


## Получение статуса звонка

Используйте этот запрос, чтобы проверить статус звонка.

```
callStatus(with callId: Int, completion: @escaping VMSResultBlock<VMSIntercomCall>)
```

## Вызов отвечен

Используйте этот запрос, чтобы сообщить серверу, что на текущем устройстве был дан ответ на вызов.

```
callAnswered(callId: Int, completion: @escaping VMSResultBlock<VMSVoipCall>)
```

## Вызов отменен

Используйте этот запрос, чтобы сообщить серверу, что вызов был отменен на текущем устройстве.

```
callCanceled(callId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

## Звонок окончен

Используйте этот запрос, чтобы сообщить серверу, что вызов был завершен на текущем устройстве.

```
callEnded(callId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

