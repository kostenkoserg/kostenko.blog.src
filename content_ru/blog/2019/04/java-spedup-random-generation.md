
title=Улучшение производительности генерации случайных чисел date=2019-04-18 type=post tags=Performance,Linux status=published

```
Каждый разработчик, прямо или косвенно, использует генерацию случайных чисел при разработке приложений по разным причинам: 

* криптография
* моделирование
* игровые движки
* генератор UUID

и многое другое...

В Java  мы имеем **ненадежный**: `java.util.Random` и  **защищённый**: `java.security.SecureRandom` рандом генераторы. Главные отличия между ними - это: 
* **Size** - 48(Random) vs 128(SecureRandom) бит, по-этому шансы повторения для последнего варианта меньше.
* **Seed Generation** - Random использует системные часы и, таким образом, может быть воспроизведен. SecureRandom в свою очередь, принимает случайные данные из вашей ОС(железа)
* **Security** - Как следствие, класс java.util.Random нельзя использовать ни для критически важных приложений, ни для защиты конфиденциальных данных.


Как результат описанных выше причин, использование SecureRandom намного предпочтительнее. Вы можете никогда не сталкиваться с проблемами производительности, пока вам не понадобится некоторое количество случайных чисел, которые можно сгенерировать за единицу времени. Особенно в облачной среде из-за плохой энтропии.

Здесь приведён простой пример использования и сравнение скорости:
```java
public class RandomGenerationTest {

    private static int count = 100_000_000;

    public static void main(String... s) throws Exception {
        System.out.println("Start...");
        doGeneration(new Random());
        doGeneration(new SecureRandom());
    }

    private static void doGeneration(Random random) {
        long time = System.currentTimeMillis();
        for (int i = 0; i < count; i++) {
            random.nextInt();
        }
        time = System.currentTimeMillis() - time;
        System.out.println(String.format("Generation of %s random numbers with %s time %s ms.", count, random.getClass().getName() ,time));
    }
}
```
```java
Generation of 100000000 random numbers with java.util.Random time 930 ms.
Generation of 100000000 random numbers with java.security.SecureRandom time 22036 ms.
```

По дефолту SecureRandom будет использовать случайные данные из пула ядра энтропии Linux `/dev/random`. Так что в случае, если пул будет пуст, следующая генерация может быть отложена на **несколько минут**. Вы также можете переключиться на генератор псевдослучайных чисел `/dev/urandom` , который может быть быстрее (без блокировки), но менее безопасным.  

Чтобы Java смогла использовать `/dev/urandom` , вам нужно изменить свойство `securerandom.source` в файле `jre/lib/security/java.security`  


```java
securerandom.source=file:/dev/urandom
```
Устройство сбора энтропии также можно указать в Системных свойствах `java.security.egd`. 
Например:

```java
java -Djava.security.egd=file:/dev/urandom MainClass
```

Чтобы проверить, сколько случайных данных в настоящее время доступно в пуле энтропии, используйте следующую команду:

```java
cat /proc/sys/kernel/random/entropy_avail
```
Кождое число, меньше, чем 1.000 можно считать низким для нормального функционирования;
если вы запрашиваете больше данных, чем доступно, запрашивающий процесс будет заблокирован. Для увеличения энтропии в среде Linux, вы можете использовать **HA**rdware **V**olatile **E**ntropy **G**athering and **E**xpansion реализацией `haveged` с открытым исходным кодом. 


```java
apt-get install haveged
```
Это будет использовать дополнительную аппаратную (CPU) статистику для увеличения энтропии и, как результат, ускорит ваше приложение.
```
