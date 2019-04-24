title=Improve performance of random number generation
date=2019-04-18
type=post
tags=Performance,Linux
status=published
~~~~~~
Directly or indirectly every developer uses random number generation during application development by different reasons:

* cryptography
* simulations
* game engines
* UUID generation

and many more...

In Java we have **insecure**: `java.util.Random` and **secure**: `java.security.SecureRandom` random generators. Main differences between is

* **Size** - 48(Random) vs 128(SecureRandom) bits, so the chances of repeating for last one are smaller.
* **Seed Generation** - Random uses the system clock and, so can be reproduced. SecureRandom takes random data from your OS (hardware)
* **Security** - Consequently, the java.util.Random class must not be used either for security-critical applications or for protecting sensitive data.

As result of above, for described reasons using SecureRandom implementation. You may never get performance issues with it until you need for number of random numbers which can be generated per time unit. Especially on cloud environment because of poor entropy.

By default SecureRandom will use random data from Linux kernel entropy pool `/dev/random`. So in case pool went empty -  next generation can be delayed for **several minutes**. You also can switch to the pseudo random number generator `/dev/urandom` which is can be must faster (non blocking) but little bit less secure.

To make Java use `/dev/urandom` you need to change `securerandom.source` property in the file `jre/lib/security/java.security`

```java
securerandom.source=file:/dev/urandom
```
The entropy gathering device can also be specified with the System property `java.security.egd`. For example:

```java
java -Djava.security.egd=file:/dev/urandom MainClass
```

To check how much random data is currently available in the entropy pool, use next command:

```java
cat /proc/sys/kernel/random/entropy_avail
```
Every number lower than 1.000 can be considered too low for normal operation; if you request more data than available the requesting process will block. To increase entropy of Linux environment you can use **HA**rdware **V**olatile **E**ntropy **G**athering and **E**xpansion with `haveged` open source implementation

```java
apt-get install haveged
```
It will use additional hardware(CPU) statistic to increase entropy and as result speedup your application.
