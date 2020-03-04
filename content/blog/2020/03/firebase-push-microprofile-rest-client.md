title=Firebase push notifications with Eclipse Microprofile Rest Client
date=2020-03-04
type=post
tags=microprofile, rest-client
status=published
~~~~~~
Nowadays **Push notifications** is a must have feature for any trend application. Firebase Cloud Messaging (**FCM**) is a free (at least in this moment) cross-platform solution for messages and notifications for Android, iOS and Web applications.

To enable push notification on client side you should create Firebase project and follow the [manual](https://firebase.google.com/docs/cloud-messaging) or  [examples](https://github.com/firebase/quickstart-js/tree/master/messaging). From the server side perspective all you need to send push notification is:

  * **Server key** - will be created for your firebase project
  * **Instance ID token** - id of specific subscribed instance (instance destination id)

Firebase provides **`https://fcm.googleapis.com/fcm/send`** endpoint and very simple [HTTP API](https://firebase.google.com/docs/cloud-messaging/http-server-ref) like

```java
{
    "to": "<Instance ID token>",
    "notification": {
      "title": "THIS IS MP REST CLIENT!",
      "body": "The quick brown fox jumps over the lazy dog."
      }
}
```
