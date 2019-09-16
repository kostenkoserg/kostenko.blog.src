title=Кластер доменного режима Wildfly и балансировка нагрузки из коробки
date=2019-04-15
type=post
tags=Wildfly
status=published
~~~~~~


Wildfly Application Server предоставляет нам два возможных режима настройки кластерной среды для приложений Java EE.

1. **Автономный режим (Standalone mode)** - каждый автономный экземпляр имеет свой собственный интерфейс управления и конфигурацию. Вы можете управлять одним экземпляром за раз. Конфигурация помещена в файл `standalone.xml`.
2. **Доменный режим (Domain mode)** - все экземпляры Wildfly управляются с помощью специального процесса оркестровки, называемого `контроллер домена`. С помощью контроллера домена вы можете управлять группой серверов. Также вы можете управлять группами. Каждая группа серверов может иметь их собственные конфигурации, развертывания и т.д. Конфигурация находится в файлах `domain.xml` и `host.xml`.
Пример группы серверов Wildfly:
![wildfly-cluster-domain-mode](/img/2019-04-wildfly-cluster-domain-mode.png)


С версии 10 Wildfly добавляет поддержку для использования подсистемы `Undertow` в качестве баланса нагрузки. Итак, теперь все, что нам нужно для создания кластерной инфраструктуры Java EE, это только Wildfly. Давай сделаем это. 

Скачайте последнюю версию сервера приложений с https://wildfly.org/downloads/ и после распакуйте дистрибутиву. Чтобы запустить Wildfly в доменном режим, пожалуйста выполните:
```java
kostenko@kostenko:/opt/wildfly-16.0.0.Final/bin$ ./domain.sh
```

Подключитесь к Wildfly CLI консоле
```java
kostenko@kostenko:/opt/wildfly-16.0.0.Final/bin$ ./jboss-cli.sh -c
[domain@localhost:9990 /]
```
По умолчанию в Wildfly предварительно настроены группы серверов `main-server-group` и` other-server-group`, поэтому нам нужно очистить существующие серверы:
```java
:stop-servers(blocking=true)
/host=master/server-config=server-one:remove
/host=master/server-config=server-two:remove
/host=master/server-config=server-three:remove
/server-group=main-server-group:remove
/server-group=other-server-group:remove
```
Создайте новую группу серверов и серверов, используя профиль `full-ha`, чтобы включить поддержку` mod_cluster`:
```java
/server-group=backend-servers:add(profile=full-ha, socket-binding-group=full-ha-sockets)
/host=master/server-config=backend1:add(group=backend-servers, socket-binding-port-offset=100)
/host=master/server-config=backend2:add(group=backend-servers, socket-binding-port-offset=200)

#start the backend servers
/server-group=backend-servers:start-servers(blocking=true)

#add system properties (so we can tell them apart)
/host=master/server-config=backend1/system-property=server.name:add(boot-time=false, value=backend1)
/host=master/server-config=backend2/system-property=server.name:add(boot-time=false, value=backend2)
```
Далее настройте группу серверов для балансировщика нагрузки.
```java
/server-group=load-balancer:add(profile=load-balancer, socket-binding-group=load-balancer-sockets)
/host=master/server-config=load-balancer:add(group=load-balancer)
/socket-binding-group=load-balancer-sockets/socket-binding=modcluster:write-attribute(name=interface, value=public)
/server-group=load-balancer:start-servers
```

Теперь давайте разработаем простую конечную точку JAX-RS, чтобы показать, как она работает:
```java
@Path("/clusterdemo")
@Stateless
public class ClusterDemoEndpoint {

    @GET
    @Path("/serverinfo")
    public Response getServerInfo() {

        return Response.ok().entity("Server: " + System.getProperty("server.name")).build();
    }
}
```
Создайте проект и задеплойте его в группе `backend-servers`:
```java
[domain@localhost:9990 /] deploy ee-jax-rs-examples.war --server-groups=backend-servers
```
И проверьте результат на `http://localhost:8080/ee-jax-rs-examples/clusterdemo/serverinfo` :
![wildfly-cluster-domain-mode-1-2](/img/2019-04-wildfly-cluster-domain-mode-1-2.gif)

Теперь мы можем легко добавить серверы в группу во время выполнения, и запросы будут автоматически балансироваться:
```java
[domain@localhost:9990 /] /host=master/server-config=backend3:add(group=backend-servers, socket-binding-port-offset=300)
[domain@localhost:9990 /] /host=master/server-config=backend3/system-property=server.name:add(boot-time=false, value=backend3)
[domain@localhost:9990 /] /server-group=backend-servers/:start-servers(blocking=true)
```
![wildfly-cluster-domain-mode-1-2-3](/img/2019-04-wildfly-cluster-domain-mode-1-2-3.gif)

Это всё!
Код этого блога доступен на GitHub:  [Demo application](https://github.com/kostenkoserg/ee-jax-rs-examples/blob/master/src/main/java/org/kostenko/example/jaxrs/ClusterDemoEndpoint.java),  [Wildlfly CLI ](https://github.com/kostenkoserg/wildfly-configuration-examples/blob/master/wildfly-domain-mode-cluster.cli)
