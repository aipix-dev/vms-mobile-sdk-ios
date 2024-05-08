@toc API/Requests/Cameras/FavoritesApi

# FavoritesApi #

API для управления избранными камерами.


## Добавление камеры в избранное

Добавить камеру в избранное по ее идентификатору.

```
createFavorite(with cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

## Удаление камеры из избранного

Удалить камеру из избранного по ее идентификатору.

```
deleteFavorite(with cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

## Получение списка избранных камер

Получить список избранных камер. Укажите страницу для запроса. Для первого запроса установите `page = 0`.

```
getFavoritesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
```

