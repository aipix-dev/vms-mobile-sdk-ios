@toc API/Requests/Cameras/GroupApi

# GroupApi #

API для управления группами камер.


## Получение списка групп

Получить список групп камер. Укажите страницу для запроса. Для первого запроса установите `page = 0`.

```
getGroupsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCameraGroup>>)
```

## Создание группы

Создать новую группу камер с указанным именем. Изначально группа не содержит камер.

```
createGroup(with name: String, completion: @escaping VMSResultBlock<VMSCameraGroup>)
```

## Переименование группы

Переименовать конкретную группу по ее идентификатору с новым именем.

```
renameGroup(with id: Int, newName: String, completion: @escaping VMSResultBlock<VMSCameraGroup>)
```

## Удаление группы

Удалить определенную группу по ее идентификатору.

```
deleteGroup(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
```

## Обновление группы

Обновить группу с указанной информацией.

```
updateGroup(info: VMSUpdateGroupRequest, completion: @escaping VMSResultBlock<VMSCameraGroup>)
```

### VMSUpdateGroupRequest

Объект с необходимой информацией для обновления группы.

```
init(groupName: String, groupId: Int, cameraIds: [Int])
```

`groupName` — новое имя группы. Если вы не хотите менять имя группы, установите в этом параметре старое имя

`groupId` — идентификатор группы, для указания необходимой группы

`cameraIds` — список идентификаторов камер, которые вы хотите добавить в эту группу


## Синхронизация групп

Этот запрос синхронизирует указанную камеру со всеми группами пользователей. В запросе требуется список групп, к которым будет принадлежать данная камера. Камера будет удалена из других групп.

```
syncGroups(for cameraId: Int, groupIds: [Int], completion: @escaping VMSResultBlock<VMSTypeGroupResponse>)
```

`cameraId` — укажите камеру по ее идентификатору

`groupIds` — укажите список идентификаторов групп, в которых будет представлена камера (камера будет добавлена в группу, если ее раньше там не было)

### VMSGroupSyncType

Информация о способе синхронизации на стороне сервера.

```
enum VMSGroupSyncType: String, Codable {
    case sync
    case async
}
```

`sync` — если синхронизация была выполнена

`async` — если у пользователя более 50 групп, серверный запрос будет выполняться асинхронно. 

После завершения процесса вы получите сообщение сокета, которое сможете обработать. Дополнительную информацию см. в `VMSPusherApi`.
