title=Understanding JMS(MDB) transaction scopes in JakartaEE application
date=2019-11-14
type=post
tags=JakartaEE, JMS, Wildfly
status=published
~~~~~~
Most useful way to deal with JMS in JakartaEE application is MDB(**M**essage **D**riven **B**eans). This type of bean acts as a JMS message listener to which messages can be delivered from either a queue or a topic.

Message Driven Bean supports only `Required` and `NotSupported` scopes as there is no incoming transaction context.

 * **@Required:** Transaction starts before read from queue (before onMessage). All next resource calls will use this transaction context. In case transaction rollback or some RuntimeException, - message will be roll back to destination. Container acknowledges delivery after TX commit;

 * **@NotSupported:** No transaction started. Application server acknowledges delivery on successful onMessage(). In case RuntimeException, - message will be returned to destination;

In both cases above, when message was returned to the destination, container will do redelivery according to application server configuration. For example on Wildfly it is: `max-delivery-attempts` and `redelivery-delay`.
```java
/subsystem=messaging-activemq/server=default/address-setting=#:read-attribute(name=max-delivery-attempts)
```
Be careful with redelivery configuration as in case **"poisen message"** it can negative affect performance of your application or even server.

When you use container-managed transactions, you can invoke next `MessageDrivenContext` methods:

 * setRollbackOnly: marks the current transaction to rollback.
 * getRollbackOnly: check current transaction has been marked for rollback or not.

In case bean-managed transactions you need to manually control transaction by `UserTransaction` methods and you also can set the activation configuration property acknowledgeMode to `Auto-acknowledge` or `Dups-ok-acknowledge` to specify how the message received by the message-driven bean to be acknowledged.

Ok. Let's pay attention on typical use cases and potentially issues with default configurations. Often enough developers use MDB to do relatively long tasks that should be executed asynchronously. So typical message bean in this case will looks like:

```java
@JMSDestinationDefinition(
        name = TxRequiredMessagerDrivenBean.TX_REQUIRED_QUEUE,
        interfaceName = "javax.jms.Queue"
)
@MessageDriven(activationConfig = {
    @ActivationConfigProperty(propertyName = "destinationLookup", propertyValue = TxRequiredMessagerDrivenBean.TX_REQUIRED_QUEUE),
    @ActivationConfigProperty(propertyName = "destinationType", propertyValue = "javax.jms.Queue")
})
//@TransactionAttribute(TransactionAttributeType.REQUIRED)
public class TxRequiredMessagerDrivenBean implements MessageListener {

    public final static String TX_REQUIRED_QUEUE = "java:global/jms/txRequiredQueue";

    @Resource
    MessageDrivenContext messageDrivenContext;

    @Override
    public void onMessage(Message msg) {
        System.out.println("Got new message.");
        try {
            System.out.println("Hello TxRequiredMessagerDrivenBean!");
            for (int x = 1; x < 40; x++) {
                Thread.sleep(10_000l);
                System.out.println("Long transaction: " + (10 * x) + " sec.");
            }
        } catch (Exception ex) {
            System.err.println(ex);
            messageDrivenContext.setRollbackOnly();
        }
        System.out.println("Message  successfully processed");
    }
}
```
Now take a look to result of our bean invocation:
```java
INFO  (Thread-1 (ActiveMQ-client-global-threads)) Got new message.
INFO  (Thread-1 (ActiveMQ-client-global-threads)) Hello TxRequiredMessagerDrivenBean!
INFO  (Thread-1 (ActiveMQ-client-global-threads)) Long transaction: 10 sec.
...
INFO  (Thread-1 (ActiveMQ-client-global-threads)) Long transaction: 290 sec.
...
WARN  [com.arjuna.ats.arjuna] (Transaction Reaper) ARJUNA012117: TransactionReaper::check timeout for TX 0:ffff7f000101:3b3ecbca:5dcc2894:13 in state  RUN
WARN  [com.arjuna.ats.arjuna] (Transaction Reaper Worker 0) ARJUNA012095: Abort of action id 0:ffff7f000101:3b3ecbca:5dcc2894:13 invoked while multiple threads active within it.
WARN  [com.arjuna.ats.arjuna] (Transaction Reaper Worker 0) ARJUNA012381: Action id 0:ffff7f000101:3b3ecbca:5dcc2894:13 completed with multiple threads - thread Thread-1 (ActiveMQ-client-global-threads) was in progress with java.lang.Thread.sleep(Native Method) org.kostenko.example.jms.transaction.TxRequiredMessagerDrivenBean.onMessage(TxRequiredMessagerDrivenBean.java:40)
...
WARN  [com.arjuna.ats.arjuna] (Transaction Reaper Worker 0) ARJUNA012108: CheckedAction::check - atomic action 0:ffff7f000101:3b3ecbca:5dcc2894:13 aborting with 1 threads active!
...
WARN  [com.arjuna.ats.arjuna] (Transaction Reaper Worker 0) ARJUNA012121: TransactionReaper::doCancellations worker Thread[Transaction Reaper Worker 0,5,main] successfully canceled TX 0:ffff7f000101:3b3ecbca:5dcc2894:13
...
INFO  (Thread-3 (ActiveMQ-client-global-threads)) Got new message.
INFO  (Thread-3 (ActiveMQ-client-global-threads)) Hello TxRequiredMessagerDrivenBean!
INFO  (Thread-1 (ActiveMQ-client-global-threads)) Long transaction: 300 sec.
INFO  (Thread-3 (ActiveMQ-client-global-threads)) Long transaction: 10 sec.
INFO  (Thread-1 (ActiveMQ-client-global-threads)) Long transaction: 310 sec.
INFO  (Thread-3 (ActiveMQ-client-global-threads)) Long transaction: 20 sec.
INFO  (Thread-1 (ActiveMQ-client-global-threads)) Long transaction: 320 sec.
...
INFO  (Thread-3 (ActiveMQ-client-global-threads)) [] Long transaction: 90 sec.
INFO  (Thread-1 (ActiveMQ-client-global-threads)) [] Long transaction: 390 sec.
INFO  (Thread-1 (ActiveMQ-client-global-threads)) [] Message  successfully processed
WARN  [com.arjuna.ats.arjuna] (Thread-1 (ActiveMQ-client-global-threads)) [] ARJUNA012077: Abort called on already aborted atomic action 0:ffff7f000101:3b3ecbca:5dcc2894:13
WARN  [org.apache.activemq.artemis.ra] (Thread-1 (ActiveMQ-client-global-threads)) [] AMQ152006: Unable to call after delivery: javax.resource.spi.LocalTransactionException: javax.transaction.RollbackException: ARJUNA016102: The transaction is not active! Uid is 0:ffff7f000101:3b3ecbca:5dcc2894:13
  Caused by: javax.transaction.RollbackException: ARJUNA016102: The transaction is not active! Uid is 0:ffff7f000101:3b3ecbca:5dcc2894:13
...
WARN  [org.apache.activemq.artemis.core.client] (Thread-1 (ActiveMQ-client-global-threads)) [] AMQ212009: resetting session after failure
```
From log above we can see that:

 * `TransactionAttributeType.REQUIRED` was used by default;
 * Started transaction was canceled by default timeout in `300 sec`;
 * Container detected TX cancellation - did message redelivery and MDB starts new transaction;
 * Old thread continue work with first message processing, but the transaction already is not active;

So, keep this behavior in mind if you planning to play with long tasks and Message Driven Beans then depends on requirements few **solutions** is possible here:

 * Avoid long transaction usage. If long TX is not necessary - always use `TransactionAttributeType.NOT_SUPPORTED`
 * Increase default transaction timeout
 * Use an annotation @ActivationConfigProperty(propertyName="transactionTimeout", propertyValue="xxx") to specify custom transaction timeout for MDB like:
 ```java
 @MessageDriven(activationConfig = {
     @ActivationConfigProperty(propertyName = "destinationLookup", propertyValue = TxRequiredMessagerDrivenBean.TX_REQUIRED_QUEUE),
     @ActivationConfigProperty(propertyName = "destinationType", propertyValue = "javax.jms.Queue")
     @ActivationConfigProperty(propertyName = "transactionTimeout", propertyValue="500")
 })
 ```  
Source code of test application available on [GitHub](https://github.com/kostenkoserg/ee-jms-examples)
