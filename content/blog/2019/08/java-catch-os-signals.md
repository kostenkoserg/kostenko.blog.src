title=How to catch 'kill' signals in java
date=2019-08-07
type=post
tags=java, linux
status=published
~~~~~~

You can send different signals to your application using **kill -l** command. By default **kill** will sent `TERM` signal. Java by default catches some types of signals, for example
```java
kill -3 <PID>
```
will dump Java stack traces to the standard error stream.

Also, you can catch `signal` inside your application, like
```java
public class App {
    public static void main(String... s) throws Exception {

        Signal.handle(new Signal("HUP"), signal -> {
            System.out.println(signal.getName() + " (" + signal.getNumber() + ")");
        });

        new Thread(new Runnable() {
            @Override
            public void run() {
                while (true) {
                    try {
                        Thread.sleep(1000l);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
        }).start();
    }
}
```
List of available signals you can get by executing `kill -l`:
```java
kostenko@kostenko:~$ kill -l
 1) SIGHUP	 2) SIGINT	 3) SIGQUIT	 4) SIGILL	 5) SIGTRAP
 6) SIGABRT	 7) SIGBUS	 8) SIGFPE	 9) SIGKILL	10) SIGUSR1
11) SIGSEGV	12) SIGUSR2	13) SIGPIPE	14) SIGALRM	15) SIGTERM
16) SIGSTKFLT	17) SIGCHLD	18) SIGCONT	19) SIGSTOP	20) SIGTSTP
21) SIGTTIN	22) SIGTTOU	23) SIGURG	24) SIGXCPU	25) SIGXFSZ
26) SIGVTALRM	27) SIGPROF	28) SIGWINCH	29) SIGIO	30) SIGPWR
31) SIGSYS	34) SIGRTMIN	35) SIGRTMIN+1	36) SIGRTMIN+2	37) SIGRTMIN+3
38) SIGRTMIN+4	39) SIGRTMIN+5	40) SIGRTMIN+6	41) SIGRTMIN+7	42) SIGRTMIN+8
43) SIGRTMIN+9	44) SIGRTMIN+10	45) SIGRTMIN+11	46) SIGRTMIN+12	47) SIGRTMIN+13
48) SIGRTMIN+14	49) SIGRTMIN+15	50) SIGRTMAX-14	51) SIGRTMAX-13	52) SIGRTMAX-12
53) SIGRTMAX-11	54) SIGRTMAX-10	55) SIGRTMAX-9	56) SIGRTMAX-8	57) SIGRTMAX-7
58) SIGRTMAX-6	59) SIGRTMAX-5	60) SIGRTMAX-4	61) SIGRTMAX-3	62) SIGRTMAX-2
63) SIGRTMAX-1	64) SIGRTMAX
```
Notice! Not all signals can be catched in application, some of them reserved by OS. For example, if you will try to handle **kill -SIGKILL (kill -9)** , then you get:
```java
Exception in thread "main" java.lang.IllegalArgumentException: Signal already used by VM or OS: SIGKILL
	at java.base/jdk.internal.misc.Signal.handle(Signal.java:173)
	at jdk.unsupported/sun.misc.Signal.handle(Signal.java:157)
```
