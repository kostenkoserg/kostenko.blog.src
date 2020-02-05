title=How to use custom ClassLoader to load jars in runtime
date=2019-06-28
type=post
tags=java
status=published
~~~~~~

To load calsses in runtime java uses ClassLoader mechanism which is based on next core principles:

 * **delegation** - by default uses `parent-first delegation`, - child ClassLoader will be used if parent is not able to find or load class. This behavior can be changed to `child-first` by overwriting `ClassLoader.loadClass(...)`;
 * **visibility** - child ClassLoader is able to see all the classes loaded by parent but vice-versa is not true;
 * **uniqueness** - allows to load a class exactly once, which is basically achieved by delegation and ensures that child ClassLoader doesn't reload the class already loaded by parent;

The main scenarios to use custom ClassLoader is:

 * **Class Instrumentation** - modifying classes at runtime. For example, to unit testing, debugging or monitoring;
 * **Isolation of executions** - isolate several execution environments within a single process by making visible only a subset of classes for a particular thread, like it does in EE environments;


So, let's see how using of custom ClassLoader looks from source code perspective:

```java
List<File> jars = Arrays.asList(new File("/tmp/jars").listFiles());
URL[] urls = new URL[files.size()];
for (int i = 0; i < jars.size(); i++) {
    try {
        urls[i] = jars.get(i).toURI().toURL();
    } catch (Exception e) {
        e.printStackTrace();
    }
}
URLClassLoader childClassLoader = new URLClassLoader(urls, ClassLoader.getSystemClassLoader());
```

Then load class with custom ClassLoader:

```java
Class.forName("org.kostenko.examples.core.classloader.ClassLoaderTest", true , childClassLoader);
```

Note! If your loaded libraries uses some resources like properties or something else, you need to provide context class loader:

```java
Thread.currentThread().setContextClassLoader(childClassLoader);  
```

Also, you can use custom ClassLoaders to load services with Java Service Provider Interface(SPI)

```java
ServiceLoader<MyProvider> serviceLoader = ServiceLoader.load(MyProvider.class, childClassLoader);
...
```
