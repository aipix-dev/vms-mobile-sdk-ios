@toc API/Requests/User/UserApi

# UserApi #

API для получения информации о пользователе, изменении его пароля и выхода из приложения.


## Получение пользователя

Получить текущую информацию о пользователе.

```
getUser(completion: @escaping VMSResultBlock<VMSUser>)
```


## Изменение пароля

Изменить пароль текущего авторизованного пользователя.

```
changePassword(info: VMSChangePasswordRequest, completion: @escaping VMSResultBlock<VMSNoReply>)
```

### VMSChangePasswordRequest

Объект с необходимой информацией для смены пароля.

`new` и `confirmNew` должны совпадать.

```
init(new: String, old: String, confirmNew: String)
```


## Изменение языка

Отслеживать смену языка пользователем внутри приложения на стороне сервера.

```
changeLanguage(language: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Выход из системы

Выход из системы текущего авторизованного пользователя.

```
logout(completion: @escaping VMSResultBlock<VMSNoReply>)
```
