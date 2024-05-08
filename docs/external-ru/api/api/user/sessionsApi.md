@toc API/Requests/User/SessionsApi

# SessionsApi #

API для управления сеансами разных пользователей.

## Получение списка сессий

Получить список различных сессий.

```
getSessionsList(completion: @escaping VMSResultBlock<[VMSSession]>)
```

## Удаление сеанса

Удалить конкретный сеанс с заданным идентификатором.

```
deleteSession(with id: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```
