title=How to generate ssh keys on Linux
date=2019-02-20
type=post
tags=Linux
status=published
~~~~~~

Sometimes, by security or usability reasons authentication with SSH keys looks much better than passwords. To generate personal keys, please, do next:

* Login your remote instance
* Generate ssh keys by
```
ssh-keygen -t rsa -f ~/.ssh/[KEY_FILENAME] -C [USERNAME]
cat [KEY_FILENAME].pub >> ~/.ssh/authorized_keys
```
* Download private key ([KEY_FILENAME]) to your local PC
* Try to connect from your local with key:
```
chmod 400 [KEY_FILENAME]
ssh -i [KEY_FILENAME] [USERNAME]@yourhost.com
```

To disable root login and password based login refer to  `/etc/ssh/sshd_config` and edid next sections:

```
PasswordAuthentication no
PermitRootLogin no
```

Then reload ssh server
```
sudo service ssh restart
```
