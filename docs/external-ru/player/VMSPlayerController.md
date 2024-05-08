@toc Player/VMSPlayerController

# VMSPlayerController #

Использует pusher-websocket-swift версии 10.0.1 с дополнительными исправлениями для работы VMSMobileSDK.

https://github.com/pusher/pusher-websocket-swift/tree/master

## Инициализация

```
static func initialization(
    viewModel: VMSPlayerViewModel, 
    delegate: VMSPlayerDelegate?, 
    openOptions: VMSOpenPlayerOptions? = nil
    ) -> VMSPlayerController
```


## VMSPlayerViewModel

```
init(
    camera: VMSCamera,
    groupCameras: [VMSCamera]?,
    user: VMSUser,
    translations: VMSPlayerTranslations,
    playerApi: VMSPlayerApi,
    options: VMSPlayerOptions,
    currentEventOption: VMSVideoEventOptions = .all
)
```

`camera` — камера, которую нужно открыть в плеере

`groupCameras` — если установить этот параметр, можно провести пальцем по плееру, чтобы изменить камеру, воспроизводимую в плеере

`user` — текущий пользователь

`translations` — словарь переводов, необходимых внутри плеера. Вы можете создать его на основе того, что вы получаете с сервера. Подробности см. в `StaticApi`

`playerApi` — объект `VSMobileSDK` или пользовательский объект, реализующий `CameraApi`, `PlayerApi` и `CameraEventsApi`

`options` — пользовательские параметры, которые можно установить для плеера

`currentEventOption` - выбранные типы событий, `.all` по умолчанию


## VMSPlayerOptions

```
init(
    language: String,
    allowVibration: Bool?,
    allowSoundOnStart: Bool?l,
    markTypes: [VMSEventType],
    videoRates: [VMSVideoRates]?,
    onlyScreenshotMode: Bool,
    askForNet: Bool,
    defaultQuality: VMSStream.QualityType
)
```

`language` — язык, который будет использоваться в плеере. Список доступных языков содержится в объекте `VMSBasicStatic`. См. `StaticsApi` для большей информации

`allowVibration` — установите значение `no`, если вы не хотите, чтобы устройство вибрировало при выборе некоторых настроек. По умолчанию: `yes`

`allowSoundOnStart` — указывает, разрешено ли проигрывателю включать звук, если в камере есть звук сразу после загрузки проигрывателя. По умолчанию `true`

`markTypes` — массив доступных типов меток. См. `StaticsApi` для получения дополнительной информации

`videoRates` — массив доступных скоростей воспроизведения видео у плеера. См. `StaticsApi` для получения дополнительной информации

`onlyScreenshotMode` - поставьте в `true`, если вы хотите скрыть всю функциональность плеера за исключением возможноси сделать скриншот в лайве

`askForNet` - поставьте в `true`, если вы хотите чтобы плеер при отстутствии WIFI соединения показал сообщение

`defaultQuality` - значение качества видеопотока, который будет выбран по умолчанию на камере, если такой видеопоток существует у камеры. По умолчанию установлено высокое

Используйте следующий метод, если хотите установить иное значение для видеопотока по умолчанию, если контроллер уже был загружен (пр. для других камер в группе, на которые можно перелистнуть внутри плеера):

```
func setDefaultQuality(quality: VMSStream.QualityType)
```


## VMSOpenPlayerOptions

Дополнительно вы можете установить параметры открытия, если вам нужно открыть плеер в определенных условиях.

```
init(
    event: VMSEvent?,
    archiveDate: Date?,
    showEventEdit: Bool,
    popNavigationAfterEventEdit: Bool,
    pushEventsListAfterEventEdit: Bool,
    openPlayerType: VMSOpenPlayerType,
    markOptions: VMSOpenPlayerMarkOptions?,
    isLiveRestricted: Bool = false
)
```

`event` — событие, которое нужно отобразить/редактировать в плеере. Параметру `isEventArchive` будет присвоено значение `true` автоматически

`archiveDate` — установите дату, если вам нужно открыть архив в определенную дату

`showEventEdit` — установите для этого параметра значение `true`, если вы хотите открыть экран редактирования событий. `event` также должно быть установлено

`popNavigationAfterEventEdit` — установите для этого параметра значение `true`, если вы хотите, чтобы плеер контроллер выскакивал после сохранения или отмены редактирования события

`pushEventsListAfterEventEdit` — установите для этого параметра значение `true`, если вы хотите отображать экран списка событий после сохранения или отмены редактирования события

`openPlayerType` — установите этот параметр в нужное значение, если вы хотите поменять тип просмотра уже открытого плеера на лайв или архив. По умолчанию используется значение `none`

`markOptions` - настройки фильтрации меток в плеере. Будет выбран указанный или "Отображать все" по умолчанию

`isLiveRestricted` - убрать возможность просмотра видео в live режиме, по умолчанию `false`


Используйте следующий метод контроллера, чтобы засетапить опции уже открытого плеера. Может быть вызван после инициализации контроллера для плеера:

`setOpenPlayerOptions(options: VMSOpenPlayerOptions)`


## VMSPlayerDelegate

VMSPlayerController использует VMSPlayerDelegate

`playerDidAppear()` — вызывается, когда плеер загружается и появляется на экране

`playerDidEnd()` - вызывается, когда контроллер плеера деинициализируется

`gotoEventsList(camera: VMSCamera)` — вызывается при нажатии кнопки «Список событий»

`soundChanged(isOn: Bool)` — вызывается при нажатии кнопки «отключить/включить звук»

`qualityChanged(quality: VMSStream.QualityType)` - вызывается при выборе нового качества видеопотока

`screenshotCreated(image: UIImage, cameraName: String, date: Date)` — вызывается, когда снимок экрана сделан из текущего кадра

`marksFiltered(markTypes: [VMSEventType])` - вызывается при фильтрации меток в плеере

`logPlayerEvent(event: String)` — если вы хотите записывать активность пользователя, этот метод предоставляет названия действий для передачи в ваше приложение

`playerDidReceiveError(message: String)` — показать ошибку плеера

`playerDidReceiveInfo(message: String)` — показать информацию о плеере

`dismissPlayerErrors()` — если вы показываете представления ошибок, имеющие время действия, отклоните их

`isUserAllowForNet()` - если вы хотите сохранить, что пользователь уже предупрежден об отсутствии WIFI соединения


## Обновление плеера

Плеер отвечает на эти имена уведомлений, чтобы обрабатывать их и соответствующим образом обновляться.

```
extension Notification.Name {
    static let noConnectionError
    static let updateUserPermissions
    static let updateUserCameras
    static let updateMarks
    static let updateMark
    static let resumePlayback
}
```

`noConnectionError` — опубликовать это уведомление в случае отсутствия соединения. Плеер прекратит воспроизведение

`updateUserPermissions` — в случае изменения прав пользователя необходимо обновить плеер

`updateUserCameras` — если вы получили сокет `cameraUpdate` и текущая камера была удалена из учетной записи пользователя, плеер будет закрыт должным образом. Это предпочтительный способ закрытия плеера

`updateMarks` — если вы получили сокет `markCreated` или `markDeleted`, используйте это уведомление для обновления плеера

`updateMark` — если вы получили сокет `markUpdated`, используйте это уведомление для обновления плеера

`resumePlayback`- если видео по какой-то причине остановилось (пр. пришёл звонок на домофон), и необходимо возобновить проигрывание видео
