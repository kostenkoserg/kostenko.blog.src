title=WFLYEJB0054: Failed to marshal EJB parameters
date=2019-08-05
type=post
tags=wildfly
status=published
~~~~~~

Usually error `WFLYEJB0054: Failed to marshal EJB parameters` can be throw by next reason:

  * Your data transfer object does not implement Serializable
  * Your transfered object does not exist in destination module classpath (for example, if you are using DTO without strong typing)


Also, you can catch this error with absolutely unexpected scenario and unclear stacktrace when your EJB throws some unchecked exception with stacktrace that has objects from points above.
