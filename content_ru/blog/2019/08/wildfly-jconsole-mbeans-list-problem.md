title=Проблемы с подключением JMX Wildfly (очень медленно и прекращается)
date=2019-08-19
type=post
tags=Wildfly, JMX
status=published
~~~~~~
JMX (Java Management Extensions ) - это технология, которая предоставляет нам возможность мониторинга приложеий (серверов приложения) с помощью **MBeans (Managed Bean)** объектов.
Список поддерживаемых MBeans можно получить с помощью инструмента **JConsole**, который уже включен в JDK. Поскольку JMX не обеспечивает строго определенный протокол коммуникации - реализация может отличаться в зависимости от производителя.
Например, для подключения к серверу приложений Wildfly вам необходимо использовать включенный в дистрибутиву скрипт `jconsole.sh`:
```java
<WFLY_HOME>/bin/jconsole.sh
```
или добавить `<WFLY_HOME>/bin/client/jboss-client.jar` в classpath:
```java
jconsole J-Djava.class.path=$JAVA_HOME\lib\tools.jar;$JAVA_HOME\lib\jconsole.jar;jboss-client.jar
```
По умолчанию Wildfly использует `timeout = 60s` для **удаленных JMX-соединений**, после того как это соединение будет разорвано:
![jconsole terminated connection](/img/2019-08-jmx-jconsole.png)
Чтобы изменить значение timeout, используйте свойство `org.jboss.remoting-jmx.timeout`:
```java
./jconsole.sh -J-Dorg.jboss.remoting-jmx.timeout=300
```
Но увеличение таймаутов не всегда является хорошим решением.
Итак, давайте искать причину медленной работы. Чтобы создать список MBeans, jconsole  рекурсивно запрашивает ВСЕ MBean, что может быть очень медленным в случае большого количества развертываний и большого количества логгеров. (Reported issue: [WFCORE-3186](https://issues.jboss.org/browse/WFCORE-3186)). Частичное решение заключается в уменьшении количества логов файлов путем измениния rotating типа из `periodic-size-rotating-file-handler ` на `size-rotating-file-handler`.      

Другой причиной крайне медленной работы может быть`Batch subsystem (JBeret)`. Он хранит много рабочей информации в своих таблицах (в памяти или на удаленной БД, зависит от конфигурации). Если эти таблицы достаточно большие - это может негативно сказаться на производительность сервера. 
Так что, если вам не нужны эти данные, просто периодически очищайте их (например, каждое повторное развертывание, если вы делаете это достаточно часто): 
```java
TRUNCATE TABLE PARTITION_EXECUTION CASCADE;
TRUNCATE TABLE STEP_EXECUTION CASCADE;
TRUNCATE TABLE JOB_EXECUTION CASCADE;
TRUNCATE TABLE JOB_INSTANCE CASCADE;  
```

С другой точки зрения, получений ВСЕХ MBeans не самое хорошое решение. Поэтому, просто используйте инструменты, которые позволят вам найти MBeans по пути. 
