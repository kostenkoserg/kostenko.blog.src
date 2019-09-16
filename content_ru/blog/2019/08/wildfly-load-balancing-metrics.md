title=Wildfly. Настройка показателей балансировки нагрузки
date=2019-08-06
type=post
tags=Wildfly
status=published
~~~~~~

Ранее я писал о [Кластер доменного режима Wildfly и балансировка нагрузки из коробки](https://kostenko.org/blog/2019/04/wildfly-cluster-domain-mode.html). Но что, если мы хотим выполнить балансировку зависящей от конкретного поведения сервера?

Подсистема Wildfly `mod_cluster` предоставляет нам несколько предопределенных типов показателей для определения наилучшей балансировки запросов:

  * **cpu**: на основе загрузки процессора
  * **mem**: основано на использовании системной памяти
  * **heap**: на основе использования кучи
  * **sessions**: на основе количества веб-сессий
  * **requests**: на основе количества запросов / сек
  * **send-traffic**: based on outgoing requests traffic
  * **receive-traffic**: на основе трафика исходящих POST запросов  
  * **busyness**: вычисляет на основе количества потоков из использования пула потоков, которые заняты обслуживанием запросов
  * **connection-pool**: на основе соединений JCA

Также вы можете настроить **weight** (влияние метрики на другие метрики) и свойства **capacity** ;
Ниже приведен пример того, как изменить значение по умолчанию на основе балансировки ЦП на балансировку на основе busyness + ЦП:

```java
/subsystem=modcluster/mod-cluster-config=configuration/dynamic-load-provider=configuration/load-metric=cpu:remove()
/subsystem=modcluster/mod-cluster-config=configuration:add-metric(type=busyness,weight=2)
/subsystem=modcluster/mod-cluster-config=configuration:add-metric(type=cpu,weight=1)
```

Если этих предопределенных типов недостаточно, вы можете обеспечить `custom-load-metric`, реализовав `org.jboss.modcluster.load.metric.impl.AbstractLoadMetric`. Для возможности использования вашей пользовательской метрики,- вам необходимо скопировать упакованный JAR-файл в модуль `modcluster` и обновить` module.xml`. Теперь вы можете использовать свою собственную метрику с вашей конфигурацией, как:

```java
 <custom-load-metric class="org.kostenko.examples.wldfly.modcluster.MyBalancingMetric">  
```
