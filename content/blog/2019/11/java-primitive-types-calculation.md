title=Never use Java primitives for math calculation
date=2019-11-08
type=post
tags=java
status=published
~~~~~~

This is well known stuff about representation of [Floating point types in java](https://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html), but time from time each developer can forget about

```java
@Test
public void primitiveTest() {

    // right way:
    BigDecimal bgDcml = BigDecimal.valueOf(100000f).multiply(BigDecimal.valueOf(750f)).multiply(BigDecimal.valueOf(15f)).setScale(0);
    BigDecimal bgDcml2 = BigDecimal.valueOf(0.04d).multiply(BigDecimal.valueOf(15.0d));

    // wrong way:
    float flt = 100000f * 750f * 15f;
    float flt2 = 0.04f * 15.0f;

    System.out.println("BigDecimal (correct): " + bgDcml);
    System.out.println(String.format("Float (incorrect): %s (%s)", flt, new BigDecimal(flt)));
    System.out.println("BigDecimal (correct): " + bgDcml2);
    System.out.println(String.format("Float (incorrect): %s", flt2));
}
```

```java
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
BigDecimal (correct): 1125000000
Float (incorrect): 1.12499994E9 (1124999936)
BigDecimal (correct): 0.600
Float (incorrect): 0.59999996
```
