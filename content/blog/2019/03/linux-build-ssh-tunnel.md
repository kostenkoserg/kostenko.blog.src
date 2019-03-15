title=How to build ssh tunnel on Linux
date=2019-03-15
type=post
tags=Linux
status=published
~~~~~~

SSH tunneling is routing local network traffic through SSH to remote hosts. Can be used, for example, to  connect to the remote application that was bound on remote local port.  

For example, to connect to mysql instance that was bound on remote local port `3306` you can use:
```bash
ssh -L 3366:localhost:3306 [USERNAME]@remotehost.com
```
or if you would like to connect with [SSH keys](https://kostenko.org/blog/2019/02/linux-generate-private-shh-key.html) :
```bash
ssh -i [KEY_FILENAME] -L 3366:localhost:3306 [USERNAME]@remotehost.com
```
After you can connect to the database, using your favorite tool on localhost:3366
