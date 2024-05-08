@toc API/Requests/StaticsApi

# StaticsApi #

Api for getting base information from your server and send to server possible tokens.


## Basic static

Get common information you need to run the app.

```
getBasicStatic(completion: @escaping VMSResultBlock<VMSBasicStatic>)
```

### VMSBasicStatic

Object you get from server with information you need to run the app.

`isCaptchaAvailable` - `true` if you need captcha information for login

`isExternalAuthEnabled` - `true` if you can login with external service

`availableLocales` - array of available languages supported on server

`version` - current version of backend


## Static

Get base information that you need for player

```
getStatic(completion: @escaping VMSResultBlock<VMSStatic>)
```

### VMSStatic

Object you get from server with information you need to run some functionality.

`cameraIssues` - issues on which you can send report to server

`videoRates` - video rates that are available for player

`markTypes` - mark types available to user

`systemEvents` - system event types available to user

`analyticEvents` analytic event types available to user

`analyticTypes` - analytic types available to user


## Check url

Check if given api url is correct.

```
checkUrl(api: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Get all translations

Get translations of given language and from specific revision.

```
getTranslations(info: VMSTranslationsRequest, completion: @escaping VMSResultBlock<VMSTranslationObject>)
```

### VMSTranslationsRequest

Object with needed information to get translations.

```
init(language: String, revision: Int)
```

`language` - requested language, array of available languages can be found in `VMSBasicStatic`. Check `StaticsApi` for more information

`revision` - number of revision from which you'll get changes in translations. Set to `0` to get all translations


## Tokens

### FCM

Send FCM token to server if you have firebase

```
sendFcmToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```

### APNS

Send APNS token to server if you use it

```
sendApnToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```

### VOIP

Send VOIP token for calls if you use it

```
sendVoipToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```
