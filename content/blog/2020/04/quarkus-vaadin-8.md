title=Rich web application on pure Java with Vaadin and Quarkus
date=2020-04-29
type=post
tags=vaadin, quarkus
status=published
~~~~~~
Recently I wrote about [REST API with Eclipse Microprofile and Quarkus](https://kostenko.org/blog/2020/02/jwt-openapi-microprofile-quarkus.html) - and it is very useful for the microservices development, but from time to time every backend Java developer **needs for the UI**. With **[Vaadin web framework](https://vaadin.com/)** you can write UI 100% in Java without getting bogged down in JS, HTML, and CSS.

Quarkus provides **`Servlet`** and  **`Websocket`** support as well, so there is no any blockers to run web application.
To bootstrap Quarkus from the scratch you can visit  **[code.quarkus.io](https://code.quarkus.io/)** and select build tool you like and extensions you need. In our case we need for:

  * **Undertow Servlet**
  * **Undertow WebSockets**

With **Vaadin 8** dependencies my **`build.gradle`** looks pretty clear:
```java
plugins {
    id 'java'
    id 'io.quarkus'
}
repositories {
     mavenLocal()
     mavenCentral()
}
dependencies {
    compile 'com.vaadin:vaadin-server:8.10.3'
    compile 'com.vaadin:vaadin-push:8.10.3'
    compile 'com.vaadin:vaadin-client-compiled:8.10.3'
    compile 'com.vaadin:vaadin-themes:8.10.3'
    implementation 'io.quarkus:quarkus-undertow-websockets'
    implementation 'io.quarkus:quarkus-undertow'
    implementation enforcedPlatform("${quarkusPlatformGroupId}:${quarkusPlatformArtifactId}:${quarkusPlatformVersion}")
}

group 'org.kostenko'
version '1.0.0-SNAPSHOT'

compileJava {
    options.encoding = 'UTF-8'
    options.compilerArgs << '-parameters'
}
```
Now we able to create **`com.vaadin.ui.UI`**
```java
@Theme("dashboard")
public class MyUI extends UI {

    @Override
    protected void init(VaadinRequest vaadinRequest) {
      ...
    }

    /**
     * VaadinServlet configuration
     */
    @WebServlet(urlPatterns = "/*", name = "MyUIServlet", asyncSupported = true, initParams = {
        @WebInitParam(name = "org.atmosphere.websocket.suppressJSR356", value = "true")}
    )
    @VaadinServletConfiguration(ui = MyUI.class, productionMode = false)
    public static class MyUIServlet extends VaadinServlet {
    }
}
```
Put Vaadin static files to the `/src/main/resources/META-INF/resources/VAADIN` and run quarkus in dev mode as usual **./gradlew quarkusDev**:
```bash
Listening for transport dt_socket at address: 5005
__  ____  __  _____   ___  __ ____  ______
 --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
 -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \   
--\___\_\____/_/ |_/_/|_/_/|_|\____/___/   
2020-04-29 09:49:37,718 WARN  [io.qua.dep.QuarkusAugmentor] (main) Using Java versions older than 11 to build Quarkus applications is deprecated and will be disallowed in a future release!
2020-04-29 09:49:38,389 INFO  [io.und.servlet] (Quarkus Main Thread) Initializing AtmosphereFramework
2020-04-29 09:49:38,579 INFO  [io.quarkus] (Quarkus Main Thread) Quarkus 1.4.1.Final started in 0.995s. Listening on: http://0.0.0.0:8080
2020-04-29 09:49:38,579 INFO  [io.quarkus] (Quarkus Main Thread) Profile dev activated. Live Coding activated.
2020-04-29 09:49:38,579 INFO  [io.quarkus] (Quarkus Main Thread) Installed features: [cdi, servlet, undertow-websockets]
2020-04-29 09:49:46,423 WARNING [com.vaa.ser.DefaultDeploymentConfiguration] (executor-thread-1)                                                                                                                                                             
=================================================================                                                                                                                                                                                            
Vaadin is running in DEBUG MODE.
Add productionMode=true to web.xml to disable debug features.
To show debug window, add ?debug to your application URL.
=================================================================
```
Example application I did based on **[vaadin/dashboard-demo](https://github.com/vaadin/dashboard-demo)** that uses nicely looking and responsive **[Valo theme](https://demo.vaadin.com/valo-theme/#!common)**

![quarkus + vaadin](/img/2020-04-quarkus-vaadin-sm.gif)

**Current solution limitations and workaround:**

  * Latest Vaadin version (14+) does not work from the box and needs for custom Quarkus extensions like [moewes/quarkus-vaadin-lab](https://github.com/moewes/quarkus-vaadin-lab) and there is still no official one :(
  * Vaadin CDI doesn't work as expected, so to access your CDI beans from the UI components you should use **`CDI.current().select(Bean.class).get();`**
  * By default Quarkus removes CDI beans from the runtime if no one @Inject them. Use **`io.quarkus.arc.Unremovable`** annotation for keep beans you need.
  * In case `java.lang.IllegalStateException:Unable to configure jsr356 at that stage. ServerContainer is null` - provide `org.atmosphere.websocket.suppressJSR356` VaadinServlet parameter as was shown in the code snippet above
  * Quarkus native mode doesn't work

Described example application source code available on [GitHub](https://github.com/kostenkoserg/quarkus-vaadin8-example)
