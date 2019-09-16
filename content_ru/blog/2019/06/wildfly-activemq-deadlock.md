title=Взаимная блокировка подсистемы Wildfly ActiveMQ
date=2019-06-29
type=post
tags=Wildfly
status=published
~~~~~~

В последнее время у меня была необычно высокая загрузка ЦП на случайном экземпляре Wildfly cluster.
Дамп потока показывает причину проблемы:

```java
Found one Java-level deadlock:
=============================

"Thread-1 (ActiveMQ-server-org.apache.activemq.artemis.core.server.impl.ActiveMQServerImpl$2@46fcd20a-1114701218)":
  waiting to lock Monitor@0x00007f45f02e20f8 (Object@0x0000000603407950, a org/apache/activemq/artemis/core/server/cluster/impl/ClusterConnectionImpl$MessageFlowRecordImpl),
  which is held by "Thread-29 (ActiveMQ-client-global-threads-2129186403)"
"Thread-29 (ActiveMQ-client-global-threads-2129186403)":
  waiting to lock Monitor@0x00007f46203b5518 (Object@0x00000004cc79a7b8, a org/apache/activemq/artemis/core/server/impl/QueueImpl),
  which is held by "Thread-1 (ActiveMQ-server-org.apache.activemq.artemis.core.server.impl.ActiveMQServerImpl$2@46fcd20a-1114701218)"

Found a total of 1 deadlock.
```

Ниже приведена часть официальной документации:

>"Если для thread-pool-max-size установлено положительное целое число больше, чем 0, пул потоков будет ограничен. Если поступают запросы и в пуле нету свободных потоков, запросы будут блокироваться до тех пор, пока поток не станет доступным. Рекомендуется использовать пул ограниченных потоков с осторожностью, поскольку это может привести к **тупиковым ситуациям**, если верхняя граница настроена слишком низко."

По-этому решение будет таковым:

```java
/subsystem=messaging-activemq/server=default:write-attribute(name=thread-pool-max-size,value=-1)
```
