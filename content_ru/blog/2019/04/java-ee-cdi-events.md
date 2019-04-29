title=Java EE CDI события. Динамический квалификатор.
date=2019-04-08
type=post
tags=Java EE, CDI
status=published
~~~~~~
Java ЕЕ предоставляет нам  хороший механизм для обработки событий, который является частью CDI для спецификации Java EE. Динамический CDI спецификатор может быть полезен для обработки событий, например, в domain driven архитектуре или при маршрутизации сообщений веб-сокета и т.д.

Генерация простого события:  
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
Наблюдатель события:
```java
@Named
public class MyEventObserver {
    public void observeEvent(@Observes String message){
        System.out.println(message);
    }
}
```
Используя CDI спецификатор,  можно определить, какой наблюдатель должен обработать событие
```java
@Qualifier
@Retention(RUNTIME)
@Target({METHOD, FIELD, PARAMETER, TYPE})
public @interface Important {
}
```
Например:
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
По-умолчанию, событие будет обработано обсервером в текущей транзакции, но можно изменить это поведение,  используя `@Observes` атрибут  `during`
```java
@Named
public class TransactionEventObserver {
    public void observeImportantMessage(@Observes(during = TransactionPhase.AFTER_SUCCESS) String message){
        System.out.println(message);
    }
}
```
Доступны следующие значения:

* IN_PROGRESS
* BEFORE_COMPLETION
* AFTER_COMPLETION
* AFTER_FAILURE
* AFTER_SUCCESS

Теперь давайте посмотрим как можно квалифицировать CDI события динамически. В примере ниже мы создадим обсервер для обработки пользовательских событий (вход в систему, выход, регистрация и т.д.), полученных из некого абстрактного источника.

Итак, сначала нам нужно создать `Qualifier` с доступными значениями событий
```java
@Qualifier
@Target({METHOD, FIELD, PARAMETER, TYPE})
@Retention(RUNTIME)
public @interface UserEvent {

    Routes value();
}
```
где Routes - это enum с доступными значениями, например:
```java
public enum Routes {
  LOGIN,
  LOGOUT,
  REGISTRATION
}
```
Потом нам нужно создать дочерний от `javax.enterprise.util.AnnotationLiteral` класс  для возможности использования квалификатора динамически.
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
Теперь давайте сгенерируем событие, используя динамический выбор наблюдателей
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
Время показать, как выглядит наш Observer.
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

    public void logout(@Observes @UserEvent(LOGOUT) String eventData) {
      ....
    }
}
```

P.S. В Java EE 8 с CDI 2.0 вы можете использовать асинхронные события CDI с помощью метода `fireAsync` и аннотации `@ObserveAsync`
