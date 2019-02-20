title=Как сгенерировать ssh ключи в Linux
date=2019-02-20
type=post
tags=Linux
status=published
~~~~~~

Часто, по соображения безопасности или юзабилити, предпочтительнее использовать ssh ключи вместо паролей. Для этого нужно:

* Логинимся на удаленный инстанс
* Генерируем ключи
```
ssh-keygen -t rsa -f ~/.ssh/[KEY_FILENAME] -C [USERNAME]
cat [KEY_FILENAME].pub >> ~/.ssh/authorized_keys
```
* Скачиваем приватный ключ  ([KEY_FILENAME]) себе
* Заходим на хост с использованием ключа
```
chmod 400 [KEY_FILENAME]
ssh -i [KEY_FILENAME] [USERNAME]@yourhost.com
```

Для того, что бы запретить логиниться с паролем и под рутом, отредактируйте  `/etc/ssh/sshd_config`:

```
PasswordAuthentication no
PermitRootLogin no
```
Затем перезагрузите ssh сервер
```
sudo service ssh restart
```
