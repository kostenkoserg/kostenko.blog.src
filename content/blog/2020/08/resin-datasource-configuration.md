title=Caucho Resin datasource configuration
date=2020-08-16
type=post
tags=resin
status=published
~~~~~~
There is few possible ways to do datasource configuration  for Jakarta EE application on Resin Application Server:

Way #1 - **Application level**. Place JDBC driver to the application classpath and edit **`WEB-INF/resin-web.xml`**
```xml
<web-app xmlns="http://caucho.com/ns/resin">
    <database jndi-name='jdbc/myds'>
        <driver type="com.microsoft.sqlserver.jdbc.SQLServerDriver">
            <url>jdbc:sqlserver://localhost:1433</url>
            <user>user</user>
            <password>password</password>
        </driver>
    </database>
</web-app>
```
Way #2 - **Application Server level**. Put JDBC driver to **`<resin_home>/lib`**  directory and edit **`<resin_home>/conf/resin.xml`**

```xml
...
<cluster id="app">
  ...
  <database>
    <jndi-name>jdbc/myds</jndi-name>
    <driver type="com.microsoft.sqlserver.jdbc.SQLServerDriver">
      <url>jdbc:sqlserver://localhost:1433</url>
      <user>user</user>
      <password>password</password>
     </driver>
     <prepared-statement-cache-size>8</prepared-statement-cache-size>
     <max-connections>20</max-connections>
     <max-idle-time>30s</max-idle-time>
   </database>
</cluster>
...
```
