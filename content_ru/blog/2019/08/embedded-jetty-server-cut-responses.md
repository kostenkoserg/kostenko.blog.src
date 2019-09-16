title=Встроенный сервер Jetty урезает ответы
date=2019-08-06
type=post
tags=Jetty
status=published
~~~~~~

Jetty сервер имеет множество вариантов конфигурации. Один из них, это `OutputBufferSize`

```java
HttpConfiguration httpConfig = new HttpConfiguration();
httpConfig.setOutputBufferSize(1024);
```
Если это свойство будет назначено значение меньше, чем ваш ответ - jetty просто будет обрезать обрезать последний.
