title=Firebase push notifications with Eclipse Microprofile Rest Client
date=2020-03-05
type=post
tags=microprofile, rest-client
status=published
~~~~~~
Nowadays **Push notifications** is a must have feature for any trend application. Firebase Cloud Messaging (**FCM**) is a free (at least in this moment) cross-platform solution for messages and notifications for **Android**, **iOS** and **Web applications**.

![firebase, push, microprofile, rest client](/img/2020-03-firebase-mp-rest-client.png)

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
So, let's design simple Microprofile REST client to deal with above:
```java
@Path("/")
@RegisterRestClient(configKey = "push-api")
public interface PushClientService {

    @POST
    @Path("/fcm/send")
    @Produces("application/json")
    @ClientHeaderParam(name = "Authorization", value = "{generateAuthHeader}")
    void send(PushMessage msg);

    default String generateAuthHeader() {
        return "key=" + ConfigProvider.getConfig().getValue("firebase.server_key", String.class);
    }
}
```
```java
public class PushMessage {

    public String to;
    public PushNotification notification;

    public static class PushNotification {
        public String title;
        public String body;
    }
}
```
and application.properties
```bash
# firebase server key
firebase.server_key=<SERVER_KEY>
# rest client
push-api/mp-rest/url=https://fcm.googleapis.com/
```

Actually, this is it! Now you able to `@Inject`  PushClientService and enjoy push notifications as well.
```java
@Inject
@RestClient
PushClientService pushService;
...
pushService.send(message);
```

If you would like to test how it works from client side perspective, - feel free to use **[Test web application](https://kostenko.org/blog/2020/03/firebase-push-microprofile-rest-client/index.htm)** to generate instance ID token and check notifications delivery.

Described sample application source code with swagger-ui endpoint and firebase.server_key available on [GitHub](https://github.com/kostenkoserg/microprofile-quarkus-example)
