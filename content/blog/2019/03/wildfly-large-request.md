title=Wildfly large request processing
date=2019-03-26
type=post
tags=Wildfly
status=published
~~~~~~

By default Undertow subsystem on Wildfly AS configured to process requests with `max-post-size`= 10MB. So, in case your request larger than 10MB you will get

```java
java.io.IOException: UT000020: Connection terminated as request was larger than 10485760
```

To increase this parameter you can edit directly `standalone` or `domain` configuration, like

```xml
<subsystem xmlns="urn:jboss:domain:undertow:3.1">
  <buffer-cache name="default"/>
  <server name="default-server">
    <http-listener name="default" socket-binding="http" max-post-size="15728640" redirect-socket="https" enable-http2="true"/>
    <https-listener name="https" socket-binding="https" max-post-size="15728640" security-realm="SSLRealm"/>
....
```

or use CLI commands as shown below:
```bash
/subsystem=undertow/server=default-server/http-listener=default/:write-attribute(name=max-post-size,value=15728640)
/subsystem=undertow/server=default-server/https-listener=https/:write-attribute(name=max-post-size,value=15728640)
```

Notice! If you are using Wildfly in domain mode with AJP load balancer, you also may need to change  `max-post-size` for `ajp-listener`

```bash
/subsystem=undertow/server=default-server/ajp-listener=ajp/:write-attribute(name=max-post-size,value=15728640)
```
