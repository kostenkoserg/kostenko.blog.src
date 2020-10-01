title=Simple trick to reload application on Tomcat
date=2020-09-30
type=post
tags=tomcat
status=published
~~~~~~

Reload tomcat application without accessing to manager console you can just by touch

```bash
cd tomcat/webapps/<application>/WEB-INF/
touch web.xml
```

The trick above **will work on other application servers** with "hot deploy" support.
