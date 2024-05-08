@toc API/Requests/User/UserApi

# UserApi #

Api to get user information, change it's password and logout from the app.


## Get user

Get current user info.

```
getUser(completion: @escaping VMSResultBlock<VMSUser>)
```


## Change password

Change password of current authorized user.

```
changePassword(info: VMSChangePasswordRequest, completion: @escaping VMSResultBlock<VMSNoReply>)
```

### VMSChangePasswordRequest

Object with needed info to change password.

`new` and `confirmNew` should match.

```
init(new: String, old: String, confirmNew: String)
```


## Change language

Keep track of user changing language inside the app on server side.

```
changeLanguage(language: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Logout

Logout current authorized user.

```
logout(completion: @escaping VMSResultBlock<VMSNoReply>)
```
