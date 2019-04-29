title=Wildfly обработка больших запросов
date=2019-03-26
type=post
tags=Wildfly
status=published
~~~~~~

По умолчанию подсистема Undertow в Wildfly AS настроена на обработку запросов с `max-post-size`= 10MB. В случае, если ваш запрос, больше, чем 10 МБ, вы получите

```java
java.io.IOException: UT000020: Connection terminated as request was larger than 10485760
```

Для увеличения этого параметра, можно отредактировать непосредственно `standalone` или `domain` конфигурации

```xml
<subsystem xmlns="urn:jboss:domain:undertow:3.1">
  <buffer-cache name="default"/>
  <server name="default-server">
    <http-listener name="default" socket-binding="http" max-post-size="15728640" redirect-socket="https" enable-http2="true"/>
    <https-listener name="https" socket-binding="https" max-post-size="15728640" security-realm="SSLRealm"/>
....
```

или используйте команды CLI как показано ниже:
```bash
/subsystem=undertow/server=default-server/http-listener=default/:write-attribute(name=max-post-size,value=15728640)
/subsystem=undertow/server=default-server/https-listener=https/:write-attribute(name=max-post-size,value=15728640)
```

Заметьте! Если Вы используете Wildfly в доменном режиме с балансировщиком нагрузки AJP, вам также может потребоваться изменить  `max-post-size` для `ajp-listener`

```bash
/subsystem=undertow/server=default-server/ajp-listener=ajp/:write-attribute(name=max-post-size,value=15728640)
```
