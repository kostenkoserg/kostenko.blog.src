title=Embedded Jetty server truncates responses
date=2019-08-06
type=post
tags=jetty
status=published
~~~~~~

Jetty server has lot of configuration options. One of them is `OutputBufferSize`

```java
HttpConfiguration httpConfig = new HttpConfiguration();
httpConfig.setOutputBufferSize(1024);
```
If this property set to value less than your respopnse - jetty just will truncate last one.
