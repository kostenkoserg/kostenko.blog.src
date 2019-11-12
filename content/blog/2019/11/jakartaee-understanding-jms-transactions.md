title=Understanding JMS(MDB) transaction scopes in JakartaEE application
date=2019-11-11
type=post
tags=JakartaEE, JMS, Wildfly
status=published
~~~~~~
Most useful way to deal with JMS in JakartaEE application is MDB(Message Driven Beans). This type of bean acts as a JMS message listener to which messages can be delivered from either a queue or a topic.

**M**essage **D**riven **B**ean supports only `Required` and `NotSupported` scopes as there is no incoming transaction context.

 * **@Required:** Transaction starts before read from queue (before onMessage). All next resource calls will use this transaction context. In case transaction rollback or some RuntimeException, - message will be rolled back to destination. Container acknowledges delivery after TX commit;

 * **@NotSupported:** No transaction started. Application server acknowledges delivery on successful onMessage(). In case RuntimeException, - message will be returned to destination;

In both cases above, when message was returned to the destination, container will do redelivery according to application server configuration. For example on WF it is: `max-delivery-attempts` and `redelivery-delay`.
```java
/subsystem=messaging-activemq/server=default/address-setting=#:read-attribute(name=max-delivery-attempts)
```
Be careful with redelivery configuration as in case **"poisen message"** it can negative affect performance of your application.

When you use container-managed transactions, you can use next `MessageDrivenContext` methods:
 * setRollbackOnly: marks the current transaction to rollback.
 * getRollbackOnly: check current transaction has been marked for rollback or not.
