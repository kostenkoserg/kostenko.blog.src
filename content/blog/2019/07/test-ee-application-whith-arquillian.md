title=Real Jakarta EE integration tests with Arquillian
date=2019-07-12
type=post
tags=Jakarta EE,Java EE,Arquillian
status=draft
~~~~~~

Arquillian - is a testing framework to write integration tests for business logic that are executed inside a container or interact with container as a client.

Why it is so important ?

 * Business logic can interact with resources or sub-system provided by container
 * Declarative services (Transactions, messaging, CDI, JAX-RS etc) get applied to the business component at runtime
