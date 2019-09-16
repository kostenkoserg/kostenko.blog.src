title=JMS обнаружение дублирующихся сообщений с Wildfly
date=2019-07-19
type=post
tags=Jakarta EE,Java EE,JMS,Wildfly
status=published
~~~~~~

Для поддержки JMS спецификация Wildfly использует Apache ActiveMQ Artemis в подсистеме active-mq. Последнее предоставляет механизм фильтрации повторяющихся сообщений без изменения кода приложения.

Чтобы включить обнаружение повторяющихся сообщений, вам просто нужно установить специальное свойтсво сообщения с уникальным значением.

```java
message.setStringProperty("_AMQ_DUPL_ID", uniqueId);
```

Итак, давайте посмотрим, как это работает на практике и создадим простой Message Driven Bean для использования сообщений:

```java
@JMSDestinationDefinition(
        name = DuplicateJMSTestBean.DUPLICATE_QUEUE,
        interfaceName = "javax.jms.Queue"
)
@MessageDriven(activationConfig = {
    @ActivationConfigProperty(propertyName = "destinationLookup", propertyValue = DuplicateJMSTestBean.DUPLICATE_QUEUE),
    @ActivationConfigProperty(propertyName = "destinationType", propertyValue = "javax.jms.Queue")
})
@TransactionAttribute(TransactionAttributeType.NOT_SUPPORTED)
public class DuplicateJMSTestBean implements MessageListener {

    public final static String DUPLICATE_QUEUE = "java:global/jms/duplicateTestQueue";

    @Override
    public void onMessage(Message msg) {
        System.out.println("Got new message.");
        MessageStorage.messages.add(msg);
        try {
            Thread.sleep(5_000l);
        } catch(Exception ignore) {}
        System.out.println("Message  successfully processed");
    }
}
```
И простую конечную точку JAX-RS для создания сообщений

```java
@Path("/")
@Stateless
@TransactionAttribute(TransactionAttributeType.NOT_SUPPORTED)
public class DuplicateTestEndpoint {

    @Inject
    private JMSContext context;
    @Resource(lookup = DuplicateJMSTestBean.DUPLICATE_QUEUE)
    private Queue queue;

    @GET
    @Path("/sendmessage")
    public Response sendMessage(@QueryParam("duplicate-id") String duplicateId) {
        try {
            ObjectMessage message = context.createObjectMessage();
            if (duplicateId == null) {
                context.createProducer().send(queue, message);
            } else {
                message.setStringProperty("_AMQ_DUPL_ID", duplicateId);
                context.createProducer().send(queue, message);
            }
            return Response.ok().entity("Message was sent.  Recieved " + MessageStorage.messages.size() + " messagges: " + MessageStorage.messages).build();
        } catch (Throwable e) {
            return Response.ok().entity("Error: " + e).build();
        }
    }
}
```
Теперь в случае, если мы отправим сообщение с тем же `_AMQ_DUPL_ID` без транзакции по адресу `http://127.0.0.1:8080/jms-examples/sendmessage?duplicate-id=myuniqueid`, мы получим в логах:

```java
WARN [org.apache.activemq.artemis.core.server] (Thread-448 (ActiveMQ-server-org.apache.activemq.artemis.core.server.impl.ActiveMQServerImpl$5@e47887a)) AMQ222059: Duplicate message detected - message will not be routed. Message information:
CoreMessage[messageID=1505,durable=true,userID=3d27afde-a9fa-11e9-af5d-0242e352ec80,priority=4, timestamp=Fri Jul 19 10:53:04 EEST 2019,expiration=0, durable=true, address=jms.queue.jms-examples_jms-examples_jms-examples_java:global/jms/duplicateTestQueue,size=416,properties=TypedProperties[__AMQ_CID=38587489-a9fa-11e9-af5d-0242e352ec80,_AMQ_DUPL_ID=myuniqueid,_AMQ_ROUTING_TYPE=1]]@145077408
```
и сообщение НЕ будет потребляться потребителем. Если вы отправите сообщение в транзакции - вы получите `Исключение` при коммите.  

Имейте в виду, что для хранения идентификаторов activemq, используют круговой кэш фиксированого размера.
```java
/subsystem=messaging-activemq/server=default:read-attribute(name=id-cache-size)
{
    "outcome" => "success",
    "result" => 20000
}
```
Поэтому, это значение должно быть достаточно большими для того, чтобы избежать перезаписи. Также, вы можете сконфигурировать постоянный кэш или этого не делать (по умолчанию: `true`) 
```java
/subsystem=messaging-activemq/server=default:write-attribute(name=persist-id-cache,value=false)
```

Исходный код, доступен на  [GitHub](https://github.com/kostenkoserg/ee-jms-examples)
