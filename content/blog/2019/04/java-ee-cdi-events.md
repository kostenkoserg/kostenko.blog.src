title=Java EE CDI events. Dynamic qualifier.
date=2019-04-08
type=post
tags=Java EE, CDI
status=published
~~~~~~

Java EE provides us really nice mechanism for event processing. Which is part of the CDI for Java specification. Dynamic qualifier for CDI Events can be very useful, for example, in domain driven design, web socket messages routing or any other stuff depends on needs.

Firing simple event looks like:  
```java
@Named
public class MyEventSource {

    @Inject
    private Event<String> myEvent;

    public void fireEvent(){
        myEvent.fire("Hello World!");
    }
}
```
then event observer like:
```java
@Named
public class MyEventObserver {
    public void observeEvent(@Observes String message){
        System.out.println(message);
    }
}
```
With CDI Qualifier (fancy annotation) you can specify which observer should serve the event
```java
@Qualifier
@Retention(RUNTIME)
@Target({METHOD, FIELD, PARAMETER, TYPE})
public @interface Important {
}
```
For  example:
```java
@Named
public class MyEventSource {

    @Inject
    @Important
    private Event<String> myEvent;
    ...
```
```java
@Named
public class MyEventObserver {
  public void observeEvent(@Observes @Important String message){
    ...
```
By default event will be fired in current transaction, but you can change this behavior with `@Observes` attribute  `during`
```java
@Named
public class TransactionEventObserver {
    public void observeImportantMessage(@Observes(during = TransactionPhase.AFTER_SUCCESS) String message){
        System.out.println(message);
    }
}
```
Available next values:

* IN_PROGRESS
* BEFORE_COMPLETION
* AFTER_COMPLETION
* AFTER_FAILURE
* AFTER_SUCCESS

Now, let's take a look on dynamically qualification of CDI event. In the example below we will create observer to serve user events like login, logout, registration etc from the abstract event source. As was noticed earlier, event can be fired from different sources depends on your needs.

So, first we need to create `Qualifier` with available events values
```java
@Qualifier
@Target({METHOD, FIELD, PARAMETER, TYPE})
@Retention(RUNTIME)
public @interface UserEvent {

    Routes value();
}
```
where Routes is enum with available values, for example:
```java
public enum Routes {
  LOGIN,
  LOGOUT,
  REGISTRATION
}
```
Then we need to create child class of `javax.enterprise.util.AnnotationLiteral` to possibility of inline instantiation of annotation type instance.
```java
public class UserEventBinding extends AnnotationLiteral<UserEvent> implements UserEvent {

    Routes routes;

    public UserEventBinding(Routes routes) {
        this.routes = routes;
    }

    @Override
    public Routes value() {
        return routes;
    }
}
```
Now, let's fire event with dynamically observer selection
```java
@Named
public class UserEventSource {

    @Inject
    private Event<String> userEvent;

    public void fireEvent(Routes route){
        userEvent.select(new UserEventBinding(route)).fire("Instead of string you can use your object");
    }
}
```
So, time to show how our Observer looks like
```java
import static Routes.*;
...

@Named
public class UserObserver {

    public void registration(@Observes @UserEvent(REGISTRATION) String eventData) {
      ....
    }

    public void login(@Observes @UserEvent(LOGIN) String eventData) {
      ....
    }

    public void logout(@Observes @UserEvent(LOGIN) String eventData) {
      ....
    }
}
```

P.S. From Java EE 8 with CDI 2.0 you can use **asynchronous CDI Events** whith `fireAsync` method and  `@ObservesAsync` annotation...
