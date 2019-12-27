title=How to setup Darcula LAF on Netbeans 11
date=2019-12-26
type=post
tags=IDE
status=published
~~~~~~
It is pity, but Apache Netbeans IDE still comes without support default **dark** mode. Enabling `Netbeans 8.2 Plugin portal` does not have any effect, so to use plugins from previous versions we need to add `New Provider` (Tools->Plugins) with next URL:

```java
http://plugins.netbeans.org/nbpluginportal/updates/8.2/catalog.xml.gz
```
![add provider](/img/2019-12-new-provider.png)

After that you should be able setup Darcula LAF in standard way

![add provider](/img/2019-12-select-laf.png)
