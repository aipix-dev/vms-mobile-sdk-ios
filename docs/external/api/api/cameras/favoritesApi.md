@toc API/Requests/Cameras/FavoritesApi

# FavoritesApi #

Api to manipulate with favorite cameras.


## Make camera favorite

Make camera favorite by it's id.

```
createFavorite(with cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Remove camera from favorites

Remove camera from favorites by it's id.

```
deleteFavorite(with cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Get list of favorite cameras

Get list of favorite cameras. Specify page for request. For the first request set `page = 0`.

```
getFavoritesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
```

