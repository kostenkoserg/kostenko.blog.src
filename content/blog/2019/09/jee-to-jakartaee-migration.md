title=Migration from JEE to JakartaEE
date=2019-09-30
type=post
tags=JakartaEE, WildFly
status=published
~~~~~~

As you probably know Java EE was moved from Oracle to the Eclipse Foundation where will evolve under the **Jakarta EE** brand.  Sept. 10, 2019 Jakarta EE Full Platform and Web Profile specifications was released by Eclipse Foundation during [JakartaOne Livestream](https://jakartaone.org/). Few days later Wildfly declared that **WildFly 17.0.1** has passed the Jakarta EE 8 TCK and certification request has been approved by the Jakarta EE Spec Committee. So, now WildFly is a Jakarta EE Full platform compatible implementation.

Let's do migration of typical [gradle EE project](https://kostenko.org/blog/2019/08/ee-application-multi-module-template.html) to the Jakarta EE and look how hard is it. Current JakartaEE version `8.0.0` is fully compatible with JavaEE version `8.0`, that means no need to change project sources, just update dependency from `javax:javaee-api:8.0` to `jakarta.platform:jakarta.jakartaee-api:8.0.0`

`updated build.gradle:`
```java
apply plugin: 'war'
dependencies {
    providedCompile "jakarta.platform:jakarta.jakartaee-api:8.0.0"
}
```
That is it! Application builds and works well under WF17.0.1

Source code of demo application available on [GitHub](https://github.com/kostenkoserg/ee-application-multi-module-gradle-template)
