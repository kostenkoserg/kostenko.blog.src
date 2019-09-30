title=Разработка DSL API на Java
date=2019-05-27
type=post
tags=Java, API
status=published
~~~~~~

Хорошо разработанный API - очень важен, так как его будут использовать не только вы, но и кто-то другой, если вы ожидаете. По-этому, что бы построить читаемый и хорошо написанный DLS(domain specific language) на Java, обычно используют паттерн Builder с несколькими простыми правилами:

* Думай дважды про названия для методов;
* Ограничивай доступность значений для каждого шага.

Окей, давайте посмотрим, как это выглядит с точки зрения исходного кода...    

Точка входа Design API
```java
public class MyAPI {
    public static UserBuilder.Registration asUser() {
        return new UserBuilder.User();
    }
}
```
Design builder, использующий интерфейсы для ограничения доступности значений, зависит от текущего шага.
```java
public class UserBuilder {
    public static class User implements Registration, Login, Password, Apply {
        private String login;
        private String password;

        @Override
        public Login doRegistration() {
            return this;
        }
        @Override
        public Password withLogin(String login) {
            this.login = login;
            return this;
        }
        @Override
        public Apply withPassword(String password) {
            this.password = password;
            return this;
        }
        @Override
        public void apply() {
            // ...
        }
    }

    public interface Registration {
        Login doRegistration();
    }
    public interface Login {
        Password withLogin(String login);
    }
    public interface Password {
        Apply withPassword(String password);
    }
    public interface Apply {
        void apply();
    }
}
```
Тогда использование, без попытки ошибиться, выглядит вот так:
```java
asUser().doRegistration()
        .withLogin("login").withPassword("password")
        .apply();
```
