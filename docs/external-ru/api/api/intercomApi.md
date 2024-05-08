@toc API/Requests/IntercomApi

# IntercomApi #

API для управления домофонами.


## Получение списка домофонов

Получение списка домофонов. Укажите страницу для запроса. Для первого запроса установите `page = 0`.

```
getIntercomsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercom>>)
```


## Получение списка кодов домофона

Получение списка кодов домофона. Укажите страницу для запроса. Для первого запроса установите `page = 0`.

```
getIntercomCodesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercomCode>>)
```

## Получения списка событий аналитики по распознаванию лица домофона

Получение списка событий домофона. Укажите страницу для запроса. Для первого запроса установите `page = 0`.


```
func getIntercomEventsList(page: Int, request: VMSIntercomFaceRecognitionRequest, completion: @escaping VMSResultBlock<PaginatedResponse<VMSEvent>>)
```

Дополнительно можно указать фильтрацию для событий.

```
struct VMSIntercomFaceRecognitionRequest {

    public let timePeriod: VMSEventTimePeriod?
}
```


## Получение списка звонков

Получение списка звонков домофона. Укажите страницу для запроса. Для первого запроса установите `page = 0`.

```
getIntercomCallsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSIntercomCall>>)
```

## Начать флоу добавления домофона

Этот запрос используется для запуска флоу добавления домофона.

Пользователь должен ввести код, полученный в результате этого запроса, а затем применить к домофону физический ключ домофона.

После этого вы получите push-уведомление, и пользователь должен ввести номер квартиры.

Если этот домофон уже был добавлен, этот запрос вернет ошибку с соответствующим информационным сообщением.

```
getActivateCode(completion: @escaping VMSResultBlock<VMSActivationCode>)
```

## Задать номер квартиры

Подключить домофон к конкретному номеру квартиры.

Создайте новую группу камер с указанным именем. Изначально группа пуста.

```
setIntercomFlat(intercomId: Int, flat: Int, completion: @escaping VMSResultBlock<VMSIntercom>)
```

## Переименование домофона

Переименовать конкретный домофон по его идентификатору на новое имя.

```
renameIntercom(with id: Int, newName: String, completion: @escaping VMSResultBlock<VMSIntercom>)
```

## Задать настройки домофона

Изменить параметры настроек конкретного домофона по его идентификатору.

```
changeIntercomSettings(with id: Int, isEnabled: Bool, timetable: VMSTimetable?, completion: @escaping VMSResultBlock<VMSIntercom>)

public final class VMSTimetable: Codable {
    public var days: [VMSDays]?
    public var intervals: [VMSIntervals]?
}
```

`id` — идентификатор домофона

`is_enabled` — установите значение `false`, если вы хотите отключить домофон. В этом случае звонки с домофона не будут поступать на текущее устройство

`timetable` — расписание домофонных звонков. Звонки будут приниматься только в выбранное время

### VMSTimetable


Расписание домофонных звонков.

Расписание можно настроить двумя способами:

- по дням
- по интервалам

Вы не можете установить оба параметра одновременно. В этом случае будут установлены интервалы.

```
init(days: [VMSDays]?, intervals: [VMSIntervals]?)
```

## Открытие двери

Открыть дверь домофона.

```
openDoor(intercomId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Создание кода

Создать код для физического открытия двери.

```
createCode(intercomId: Int, name: String, expiredAt: Date, completion: @escaping VMSResultBlock<VMSIntercomCode>)
```


`intercomId` — идентификатор домофона

`name` — наименование нового кода

`expiredAt` — дата, до которой этот код будет действителен


## Удаление дофомонов

Удалите домофоны, которые вам больше не нужны.

```
deleteIntercoms(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Удаление кодов домофона

Удалите коды домофона, которые вам больше не нужны.

```
deleteIntercomCodes(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Удаление звонков

Удалите звонки, которые вам больше не нужны.

```
deleteCalls(with ids: [Int], completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Создание ресурса для события распознавания лица домофона

Для домофона возможно настроить аналитику по распознаванию лиц. Для этого необходимо создать ресурс (фотографию с лицом, которое необходимо распознавать).

```
func createFaceRecognitionAnalyticFile(intercomId: Int, request: VMSIntercomFaceRecognitionResourceRequest, completion: @escaping VMSResultBlock<VMSAnalyticFile>)
```

### VMSIntercomFaceRecognitionResourceRequest

```
struct VMSIntercomFaceRecognitionResourceRequest {
    
    public let name: String
    public let image: Data
    
    init(name: String, image: Data)
}
```

`name` - название ресурса

`image` - данные изображения, максимальный размер - 5MB


## Редактирование названия ресурса для домофона

Редактировать название ресурса для события распознавания лица домофона.

```
func updateIntercomAnalyticFileName(intercomId: Int, fileId: Int, name: String, completion: @escaping VMSResultBlock<VMSAnalyticFile>)
```

## Удаление ресурса для домофона

Удалить ресурс для события распознавания лица домофона.

```
func deleteIntercomAnalyticFile(intercomId: Int, fileId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

## Получения списка ресурсов для событий аналитики по распознаванию лица домофона

Получение списка ресурсов для событий домофона. Укажите страницу для запроса. Для первого запроса установите `page = 0`.

```
func getIntercomAnalyticFiles(page: Int, intercomId: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSAnalyticFile>>)
```
