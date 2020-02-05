title=JAX-RS Client ThreadPool leak
date=2019-10-04
type=post
tags=wildfly,jax-rs
status=published
~~~~~~

Recently got resource(ThreadPool\Thread) leak with JAX-RS Client implementation on WF10.0.1 (RestEasy).
![jax-rs thread leak](/img/2019-10-thraed-leak.png)

From the dump above we can see, that pool number is extremely height, the same time thread number is always 1. That means that some code uses `Executors.new*`, which returns `java.util.concurrent.ThreadPoolExecutor` using the DefaultThreadFactory.

Actually in this situation, it is **ALL** than we can see from thread and heap dumps when debugging leak like above. Because in case classes containing these executors was garbage collected, the executors get orphaned (but are still alive and uncollectable), making it difficult/impossible to detect from a heap dump where the executors came from.

**Lesson #1** is: Doing `Executors.new*`, would be nice to little bit think about guys who will support your code and provide non default thread names with custom ThreadFactory like :)

```java
ExecutorService es = Executors.newCachedThreadPool(new CustomThreadFactory());

...

class CustomThreadFactory implements ThreadFactory {

    @Override
    public Thread newThread(final Runnable r) {
        return new Thread(r, "nice_place_for_helpful_name");
    }
}
```


So, after many times of investigation and "heap walking"(paths to GC root) i found few `Executors$DefaultThreadFactory` like

![jax-rs thread leak](/img/2019-10-thraed-leak-1.png)


what made me see the code with REST services invocations. Something like

```java
public void doCall() {
    Client client = ClientBuilder.newClient();
    Future<Response> future = client.target("http://...")
                                 .request()
                                 .async().get();
}
```
According to WF10 JAX-RS implementation each `newClient()` will build ResteasyClient that uses `ExecutorService asyncInvocationExecutor` to do requests and potentially it is can be the reason of the leak.

**Lesson #2** is: Always! do `close()` client after usage. Check that implementation closes connection and shutdowns ThreadPool in case errors (timeouts, socket resets, etc).

**Lesson #3** is: Try to construct only a small number of Client instances in the application. Last one is still bit unclear from the pure JakartaEE application point of view, as it not works as well in  multi-threaded environment. (`Invalid use of BasicClientConnManager: connection still allocated. Make sure to release the connection before allocating another one.`)

P.S. Many thanks for JProfiler tool trial version to make me happy with ThreadDump walking.
