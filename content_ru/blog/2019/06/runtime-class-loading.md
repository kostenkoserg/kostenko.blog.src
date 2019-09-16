title=Как использовать пользовательский ClassLoader для загрузки JAR-файлов во время выполнения
date=2019-06-28
type=post
tags=Java
status=published
~~~~~~

Для загрузки классов во время выполнения java используют механизм ClassLoader, который основан на нескольких основных принципах:

 * **делегирование** - по умолчанию используют `parent-first delegation`, - наследник ClassLoader будет использоваться, если родитель не может найти или загрузить класс. Это поведение можно изменить на `child-first`, переписав `ClassLoader.loadClass(...)`;
 * **видимость** - наследник ClassLoader может видеть все классы, загруженные родителем, но наоборот не может;
 * **уникальность** - позволяет загрузить класс только один раз, что в основном достигается делегированием и гарантирует, что наследник ClassLoader не перезагрузит класс, уже загруженного родителя;

Основные сценарии использования пользовательского ClassLoader:

 * **Инструментарий класса** - изменение классов во время выполнения. Например, для модульного тестирование, отладки или мониторинга;
 * **Изоляция выполнения** - изолировать несколько сред выполнения в одном процессе, делая видимыми только подмножество классов для конкретного потока, как это делается в средах EE;

 
Итак, давайте посмотрим, как выглядит использование пользовательского ClassLoader с точки зрения исходного кода:

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

Затем загрузите класс с пользовательским ClassLoader:

```java
Class.forName("org.kostenko.examples.core.classloader.ClassLoaderTest", true , childClassLoader);
```

Обратите внимение! Если ваши загруженные библеотеки используют некоторые ресурсы, такие как свойства или что-то ещё, вам нужно продоставить загрузчик класса котекста:

```java
Thread.currentThread().setContextClassLoader(childClassLoader);  
```

Кроме того, вы можете использовать пользовательские ClassLoaders для загрузки служб с помощью Java Service Provider Interface(SPI)

```java
ServiceLoader<MyProvider> serviceLoader = ServiceLoader.load(MyProvider.class, childClassLoader);
...
```
