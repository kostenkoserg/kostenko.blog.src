title=Jakarta EE application multi module gradle template
date=2019-08-08
type=post
tags=Jakarta EE,Gradle
status=published
~~~~~~
In this post i will share simple and useful **gradle** template to organize multi module Jakarta EE application. We will implement typical one which consists from REST controller (**module1**) and some main logic (**module2**). Big picture of our application architecture is:

![EE multi module application](/img/2019-08-ee-multimodule-template-arch.png)

So, lets do initialization of project with next  gradle template:
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
Above, we described initial application structure, where **module1** is flat sub project for our controller and **module2** is our main logic which consists from `API` and `Core` sub projects. As controller will use main logic API and we decided to separate application to modules (that means no big enterprise archive) - our sub projects should be simple enough:

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

Actually, that's it!
Now we can implement our controller like:
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
In turn, main logic `API` contents from `Interface` and `DTO`:
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
In the end, main logic `Core` contents from the logic that implements API:
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

Described Jakarta EE application architecture allows us enjoy all power of EE with absolutely transparent inter module interactions and, the same time, stay close to micro service design - as we have no limits with using one container for all modules.

Source code of this demo available on [GitHub](https://github.com/kostenkoserg/ee-application-multi-module-gradle-template)
