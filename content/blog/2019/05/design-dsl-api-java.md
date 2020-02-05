title=Design DSL API in Java
date=2019-05-27
type=post
tags=java, api
status=published
~~~~~~

Well designed API is very important in case you expect your API will use someone else instead of just you. To build readable and writable DSL(domain specific language) in Java usually uses Builder pattern with few simple rules:

* Think twice about names for methods
* Restrict available values for each step

So, lets see how it looks from source code perspective...

Design API entry point
```java
public class MyAPI {
    public static UserBuilder.Registration asUser() {
        return new UserBuilder.User();
    }
}
```
Design builder using interfaces to restrict available values depends on current step
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
Then usage, with no chance to mistake, looks like
```java
asUser().doRegistration()
        .withLogin("login").withPassword("password")
        .apply();
```
