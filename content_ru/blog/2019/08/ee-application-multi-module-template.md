title=Jakarta EE мультимодульный шаблон приложения
date=2019-08-08
type=post
tags=Jakarta EE,Gradle
status=published
~~~~~~
В этом посту я поделюсь простым и полезным **gradle** шаблоном для создания мультимодульного Jakarta EE приложения. Мы реализуем один из типичных, который состоит из REST контроллера (**module1**) и некоторой основной логики (**module2**). Общая картина архитектуры нашего приложения выглядит вот так:

![EE multi module application](/img/2019-08-ee-multimodule-template-arch.png)

Итак, давайте сделаем инициализацию проекта с помощью следующего gradle шаблона:
`settings.gradle:`
```java
rootProject.name = 'ee-application-multi-module-gradle-template'
include 'module1'
include 'module2:module2-api', 'module2:module2-core'
```
`root build.gradle:`
```java
defaultTasks 'clean', 'build'
subprojects {
    ext.libraryVersions = [
        javaee                  : '8.0',
    ]
    defaultTasks 'clean', 'build'
    repositories {
        jcenter()
    }
}
```
Выше, мы описали начальную структуру приложения, где **module1** является плоским подпроектом для нашего контроллера, а **module2** является нашей основной логикой, которая состоит из подпроектов `API` и `Core`. В качестве контроллера, мы будем использовать  основную логику API, и мы решили разделить приложение на модули (что означает отсутсвие общеорганизационных архивов) - наши подпроекты должны быть достаточно простыми: 

`module1 build.gradle:`
```java
apply plugin: 'war'
dependencies {
    compile project(':module2:module2-api')
    providedCompile "javax:javaee-api:${libraryVersions.javaee}"
}
```
`module2:module2-api:`
```java
apply plugin: 'java'
dependencies {
}
```
`module2:module2-core:`
```java
apply plugin: 'war'
dependencies {
    compile project(':module2:module2-api')
    providedCompile "javax:javaee-api:${libraryVersions.javaee}"
}
```

На самом деле, это всё!
Теперь мы можем реализовать наш контроллер следующим образом:
```java
@Path("/")
@Stateless
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class TestEndpoint {

    @EJB(lookup = TestService.TEST_SERVICE_JNDI)
    TestService testService;

    @GET
    @Path("/test")
    public Response test() {
        SomethingDto something = testService.doSomething();
        return Response.ok().entity(something.getMessage()).build();
    }
```
В свою очередь, основная логика `API` содержиться в `Interface` и `DTO`:
`TestService.java:`
```java
public interface TestService {

  String TEST_SERVICE_NAME = "test-service";
  String TEST_SERVICE_JNDI ="java:global/module2-core/" + TEST_SERVICE_NAME;

  SomethingDto doSomething();
}
```
`SomethingDto.java:`
```java
public class SomethingDto implements Serializable{
  ...
}
```
В конце концов, основная логика `Core` состоит из логики, реализующей API:
`TestServiceImpl.java`
```java
@Remote(TestService.class)
@Stateless(name = TestService.TEST_SERVICE_NAME)
public class TestServiceImpl implements TestService {

    @PersistenceContext
    EntityManager entityManager;

    @Override
    public SomethingDto doSomething() {
        TestEntity entity = entityManager.find(TestEntity.class, Long.MAX_VALUE);
        return new SomethingDto("Hello Jakarta EE world!");
    }
}
```

Описанная архитектура приложений Jakarta EE позволяет нам наслаждаться всеми возможностями ЕЕ с абсолютно прозрачными взаимодействиями между модулями и в то же время оставаться близким к дизайну микросервисов - поскольку у нас нет ограничений в использований одного контейнера для всех модулей.

Исходный код, доступен на [GitHub](https://github.com/kostenkoserg/ee-application-multi-module-gradle-template)
