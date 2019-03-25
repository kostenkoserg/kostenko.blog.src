title=Как поднять ssh тоннель на Linux
date=2019-03-15
type=post
tags=Linux
status=published
~~~~~~

SSH тоннель позволяет перенаправлять локальный трафик через SSH на удаленный хост. Может быть использован, например, для соедиения с удаленным приложением, которое было запущено на локальном порту удаленного хоста.

Например, чтобы соединиться с mysql, который был запущен на локальном порту `3306` хоста  remotehost.com, вы можете использовать:
```bash
ssh -L 3366:localhost:3306 [USERNAME]@remotehost.com
```
или с использованием  [SSH keys](https://kostenko.org/blog/2019/02/linux-generate-private-shh-key.html) :
```bash
ssh -i [KEY_FILENAME] -L 3366:localhost:3306 [USERNAME]@remotehost.com
```
После этого, вы можете соединиться с базой, используя любимый тулинг на localhost:3366
