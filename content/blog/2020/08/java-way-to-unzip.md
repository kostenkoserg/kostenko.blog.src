title=Unzip without root but with java
date=2020-08-06
type=post
tags=linux
status=published
~~~~~~
If you need to **unzip** file on the server, where is no root and no `unzip` installed then time to ask **java** about:

```bash
jar xvf wildfly-20.0.1.Final.zip
```
