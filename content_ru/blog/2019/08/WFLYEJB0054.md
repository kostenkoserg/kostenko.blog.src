title=WFLYEJB0054: Failed to marshal EJB parameters
date=2019-08-05
type=post
tags=Wildfly
status=published
~~~~~~

Обычно ошибка `WFLYEJB0054: Failed to marshal EJB parameters` может быть вызвана по следующим причинам:

  * Ваш объект передачи данных не имплементируется  Serializable
  * Ваш объект передачи данных не существует в пути к классу модуля назначения (например, если вы используете  DTO  без строгой типизации)


Кроме того, вы можете словить эту ошибку с абсолютно неожиданным сценарием и нечеткой трассировкой стека, когда ваш EJB выбрасывает несколько непроверяемых ошибок со стековой трассировкой, которая имеет объекты из точек выше.
