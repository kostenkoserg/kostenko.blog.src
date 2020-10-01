title=JPA @ManyToOne. Keep separate reference by ID and by Entity
date=2020-10-01
type=post
tags=jakartaee, jpa, hibernate
status=published
~~~~~~

Some time you may need to keep reference by class and reference by ID for your **JPA @Entity**. It can be very helpful, for example, to do some default JSON serialization with no risk to stuck with well known **N+1** issue. In this case i would like to avoid **@OneToMany** and **@ManyToOne** fields serialization by default and use ID reference instead.

So, below is simple example how to do above.

```java
@Entity
@Table(name = "book")
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    @Column(name = "name")
    private String name;

    @JoinColumn(name = "author", insertable = false, updatable = false)
    @ManyToOne(targetEntity = Author.class, fetch = FetchType.LAZY)
    private Author author;

    @Column(name = "author")
    private long authorId;
    ...
    public void setAuthor(Author author) {
        setAuthorId(author.getId());
        this.author = author;
    }
    ...
}
```
Testing time:

```java
public class ManyToOneTest {
    @Test
    public void relationManyToOneTest() {
        EntityManager em = Persistence.createEntityManagerFactory("myDSTest").createEntityManager();
        this.generateTestData(em);

        List <Book> books =em.createQuery("FROM Book", Book.class).getResultList();
        // lazy loading test
        for (Book b : books) {
            System.out.println("Bookd:" + b.getName());
            System.out.println("AuthorId:" + b.getAuthorId());
            // lazy load
            System.out.println("Author:" + b.getAuthor());
        }
        // JPQL with direct id reference
        books = em.createQuery("FROM Book where authorId = 1", Book.class).getResultList();
        // JPQL with author.id reference
        books = em.createQuery("FROM Book where author.id = 1", Book.class).getResultList();
    }

    private void generateTestData(EntityManager em) {
        em.getTransaction().begin();

        Author author = new Author();
        author.setName("A Name");
        em.persist(author);

        Book book = new Book();
        book.setName("Book Name");
        book.setAuthorId(author.getId());
        //book.setAuthor(author);
        em.persist(book);
        em.getTransaction().commit();
        em.clear();
    }
}
```
Test Output:
```bash
...
Hibernate: select book0_.id as id1_2_, book0_.author as author2_2_, book0_.name as name3_2_ from book book0_
Bookd:Book Name
AuthorId:1
# call book.getAuthor():
Hibernate: select author0_.id as id1_0_0_, author0_.name as name2_0_0_ from author author0_ where author0_.id=?
Author:Author{id=1, name=A Name}

```

**PS:** `book.getAuthor().getId()` **will not trigger Author lazy loading**, but book.getAuthor().getName() will.

Source code of described application available on [GitHub](https://github.com/kostenkoserg/ee-jpa-examples)
