@toc API/Requests/EventsListApi

# EventsListApi #

API для получения всех событий пользователя.

### Получение камеры с аналитикой

Получение списка камер по страницам и при необходимости выполнение поиска там, где у пользователя включена аналитика.

```
getCamerasWithAnalytics(page: Int, search: String?, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
```

## События

### Получение меток

Получение списка меток.

```
getEventsMarks(page: Int, request: VMSEventsRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
```

### Получение системных событий

Получение списка системных событий.

```
getEventsSystem(page: Int, request: VMSEventsRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
```

### Получение событий аналитики

Получение списка событий аналитики.

```
getEventsAnalytic(page: Int, request: VMSEventsAnalyticRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
```

### Получение кейсов аналитики

Получение всех кейсов определенных типов аналитики. См. `StaticsApi` для получения всех доступных типов аналитики.

```
getEventsAnalyticCases(page: Int, analyticCasesTypes: [String], completion: @escaping  VMSResultBlock<PaginatedResponse<VMSAnalyticCase>>)
```

### Информация, необходимая для отправки запросов на получение событий

```
public struct VMSEventsRequest {
    public let cameraIds: [Int]
    public let types: [String]
    public let sortDirection: VMSSortDirection
    public let timePeriod: VMSEventTimePeriod?
}
```

`types` — если вы хотите получить метки, отправьте типы меток. Если вы хотите получить список событий, отправьте типы событий. Дополнительную информацию см. в `StaticsApi`

`timePeriod` — период времени, за который вам нужно брать события. Может быть `specific` или `setManualy`, в случае `setManualy` установите даты `from` и `to` соответственно

```
public struct VMSEventsAnalyticRequest {
    public let eventNames: [String]
    public let caseIds: [Int]
    public let cameraIds: [Int]
    public let analyticEventTypes: [String]
    public let sortDirection: VMSSortDirection
    public let timePeriod: VMSEventTimePeriod?
}
```

`analyticEventTypes` — типы событий аналитики. Подробную информацию см. в `StaticsApi`

`eventNames` — имя события, которое вы получаете из `availableEvents` объекта `VMSAnalyticCase`

`timePeriod` — период времени, за который вам нужно брать события. Может быть `specific` или `setManualy`, в случае `setManualy` установите даты `from` и `to` соответственно

```
public enum VMSSortDirection: String {
    case ascending = "asc"
    case descending = "desc"
}
```


