title=JMS Duplicate Message Detection with Wildfly
date=2019-07-19
type=post
tags=jakartaee, jms, wildfly
status=published
~~~~~~

To support JMS specification Wildfly uses Apache ActiveMQ Artemis over active-mq subsystem. Last one provides mechanism to filtering out duplicate messages without application code changes.

To enable duplicate message detection you just need to set a special property on the message to a unique value

```java
message.setStringProperty("_AMQ_DUPL_ID", uniqueId);
```

So, lets see how it works on practice and create simple Message Driven Bean to consume messages:

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

And simple JAX-RS endpoint to produce messages

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
Now in case we send message with the same `_AMQ_DUPL_ID` without transaction by `http://127.0.0.1:8080/jms-examples/sendmessage?duplicate-id=myuniqueid` we will get in logs:

```java
WARN [org.apache.activemq.artemis.core.server] (Thread-448 (ActiveMQ-server-org.apache.activemq.artemis.core.server.impl.ActiveMQServerImpl$5@e47887a)) AMQ222059: Duplicate message detected - message will not be routed. Message information:
CoreMessage[messageID=1505,durable=true,userID=3d27afde-a9fa-11e9-af5d-0242e352ec80,priority=4, timestamp=Fri Jul 19 10:53:04 EEST 2019,expiration=0, durable=true, address=jms.queue.jms-examples_jms-examples_jms-examples_java:global/jms/duplicateTestQueue,size=416,properties=TypedProperties[__AMQ_CID=38587489-a9fa-11e9-af5d-0242e352ec80,_AMQ_DUPL_ID=myuniqueid,_AMQ_ROUTING_TYPE=1]]@145077408
```
and message will NOT consume by consumer. In case you send message in transaction - you will get `Exception` on commit.

Keep in mind, that to store IDs activemq uses circular fixed size cache
```java
/subsystem=messaging-activemq/server=default:read-attribute(name=id-cache-size)
{
    "outcome" => "success",
    "result" => 20000
}
```
so, this value should be big enough to avoid rewriting. Also, you can configure persist cache or not (by default: `true`)
```java
/subsystem=messaging-activemq/server=default:write-attribute(name=persist-id-cache,value=false)
```

Source code available on [GitHub](https://github.com/kostenkoserg/ee-jms-examples)
