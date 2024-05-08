@toc Player/VMSPlayerController

# VMSPlayerController #

Uses pusher-websocket-swift of 10.0.1 version with some fixes for VMSMobileSDK purposes.

https://github.com/pusher/pusher-websocket-swift/tree/master

## Initialization

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

`camera` - camera you want to open player for

`groupCameras` - if you set this parameter you can swipe inside player to change camera playing in player

`user` - current user

`translations` - dictionary of translations needed inside player. You can make it based on the on you receive from server. See `StaticsApi` for details

`playerApi` - basically `VMSMobileSDK` object. Or custom object that implements `CameraApi`, `PlayerApi` and `CameraEventsApi`

`options` - custom options you can set for player

`currentEventOption` - selected video events types, `.all` by default

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

`language` - laguage that will be used in player. Array of available laguages can be found in `VMSBasicStatic` object. Check `StaticsApi` for more information

`allowVibration` - set to `no` if you don't want device to vibrant when clicking on some options. Default is `yes`

`allowSoundOnStart` - indicates if allow player to start audio if camera has sound right after player loaded. Default is `true`

`markTypes` - array of available mark types. See `StaticsApi` for more information

`videoRates` - array of available player video rates. See `StaticsApi` for more information

`onlyScreenshotMode` - set true if you want no other player functionality available except to make screenshot on live

`askForNet` - set true if you want to ask player is no WIFI connection

`defaultQuality` - default stream quality that will be loaded at first place for a camera if possible. High quality by default


Use this method of VMSPlayerController if you want to change default video quality after controller is already opened (ex. set other quality for swiping cameras inside group):

```
func setDefaultQuality(quality: VMSStream.QualityType)
```


## VMSOpenPlayerOptions

Additionally you can set open options if you need to open player in specific conditions.

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

`event` - event you want to show / edit in player. Parameter `isEventArchive` will be set to `true` automatically

`archiveDate` - set date if you need to open archive at specific date

`showEventEdit` - set this parameter to `true` if you want to open event editing screen. `event` should be set as well

`popNavigationAfterEventEdit` - set this parameter to `true` if you want player controller to be popped after saving or canceling event editing

`pushEventsListAfterEventEdit` - set this parameter to `true` if you want to show events list screen after saving or canceling event editing

`openPlayerType` - set this parameter if you want to change already opened player to archive or live in player controller. Default is `none`

`markOptions` - mark filterind settings. Marks in player will be filtered. "Show all" by default

`isLiveRestricted` - hide possibility to show live in player, default is `false`


Use this method to set open options to your already opened player. May be called after player is initialized:

`setOpenPlayerOptions(options: VMSOpenPlayerOptions)`


## VMSPlayerDelegate

VMSPlayerController uses VMSPlayerDelegate

`playerDidAppear()` - get called when player loaded and appeared on screen

`playerDidEnd()` - get called when player controller is deititializing

`gotoEventsList(camera: VMSCamera)` - get called when button «Events list» pressed

`soundChanged(isOn: Bool)` - get called when button «mute/unmute» pressed

`qualityChanged(quality: VMSStream.QualityType)` - get called when new quality option is chosen

`screenshotCreated(image: UIImage, cameraName: String, date: Date)` - get called when screenshot captured fom current frame

`marksFiltered(markTypes: [VMSEventType])` - get called when filter for marks applied

`logPlayerEvent(event: String)` - if you want to log user activity, this method provides the action's names to transfer to your app

`playerDidReceiveError(message: String)` - show player error

`playerDidReceiveInfo(message: String)` - show player info

`dismissPlayerErrors()` - if you show views for error that have lifetime, dismiss them

`isUserAllowForNet()` - if you want to save is network connection when there is no WIFI


## Update player

Player respond to these notification names in order to handle them and be updated accordingly

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

`noConnectionError` - post this notification in case there is no connection. Player will stop playing

`updateUserPermissions` - in case user's permissions were changed player needs to be updated

`updateUserCameras` - in case you received `camerasUpdate` socket and current camera was removed from user's account player will be closed properly. It's a preferable way of closing player

`updateMarks` - in case you received socket push `markCreated` or `markDeleted` use this notification to update player

`updateMark` - in case you received socket push `markUpdated` use this notification to update player

`resumePlayback`- in case player paused for some reason (ex. intercom call) and you need to resume video playback
