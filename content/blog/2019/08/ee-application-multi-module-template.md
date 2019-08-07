title=Jakarta EE applications multi module gradle template
date=2019-08-08
type=post
tags=Jakarta EE,Java EE,Arquillian
status=draft
~~~~~~

In this post i will show you simple and useful gradle template to organize multi module Jakarta EE application.

So, lets imagine part of typical EE application that contents from REST controller (**module1**) and some main logic (**module2**)

`settings.gradle:`
```java
rootProject.name = 'ee-application-multi-module-gradle-template'
include 'module1'
include 'module2:module2-api', 'module2:module2-core'
```

`root build.gradle:`
```java
apply plugin: 'java'
defaultTasks 'clean', 'build'
subprojects {
    ext.libraryVersions = [
        javaee                  : '8.0',
        wildfly                 : '16.0.0.Final',
    ]
    apply plugin: 'war'
    group = 'org.kostenko'
    version = '0.1'
    defaultTasks 'clean', 'build'
    repositories {
        jcenter()
    }
    dependencies {
        providedCompile "javax:javaee-api:${libraryVersions.javaee}"
    }
}
```
For example, **module1** is a simple controller that depends on **module2** API:

`module1 build.gradle:`
```java
apply plugin: 'war'
dependencies {
    compile project(':module2:module2-api')
}
```

In turn **module2** contents from

  * API part - ....
  * Core part - ...
