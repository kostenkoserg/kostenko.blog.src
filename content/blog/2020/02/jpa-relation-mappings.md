title=Simple note about using JPA relation  mappings
date=2020-02-14
type=post
tags=jpa
status=published
~~~~~~
There is a lot of typical examples how to build JPA `@OneToMany` and `@ManyToOne` relationships in your Jakarta EE application. And usually it looks like:

```java
@Entity
@Table(name = "author")
public class Author {
    @OneToMany
    private List<Book> book;
    ...
}
```

```java
@Entity
@Table(name = "book")
public class Book {
    @ManyToOne
    private Author author;
    ...
}
```

This code looks pretty clear, but on my opinion **you should NOT USE this style** in your real world application. From years of JPA using experience i definitely can say that sooner or later your project will stuck with known performance issues and holy war questions about: **N+1**, **LazyInitializationException**, **Unidirectional @OneToMany** , **CascadeTypes** ,**LAZY vs EAGER**, **JOIN FETCH**, **Entity Graph**, **Fetching lot of unneeded data**, **Extra queries (for example: select Author by id before persist Book)** etcetera.  Even if you are have answers for each potential issue above, usually proposed solution will add unreasonable complexity to the project.

To avoid potential issues i recommend to follow next rules:

 * Avoid using of `@OneToMany` at all
 * Use `@ManyToOne` by **ID** instead of Entity

  ```java
  @ManyToOne(targetEntity = Author.class)
  private long authorId;
  ```
Hope, this two simple rules helps you enjoy all power of JPA with KISS and decreasing count of complexity.
