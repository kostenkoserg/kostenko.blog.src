title=Java EE CDI events. Dynamic qualifier.
date=2019-04-08
type=post
tags=Java EE, CDI
status=published
~~~~~~

Java EE provides us really nice mechanism for event processing. Which is part of the CDI for Java specification. Dynamic qualifier for CDI Events can be very useful, for example, in domain driven design, web socket messages routing or any other stuff depends on needs.

So, firing simple event looks like:  
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
By default event will be fired in current transaction, but you can change this behavior with `@Observes`attribute `during`
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


Now, let's take a look on dynamically qualification of CDI event. To do that
