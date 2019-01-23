title=Как поднять блог на github и jbake
date=2019-01-18
type=post
tags=github, jbake
status=published
~~~~~~

Развернуть свой персональный блог, блог компании или лендинг проекта используя [github](https://pages.github.com/) - задача, как оказалось, несложная и не требующая особых навыков. Здесь я, максимально конструктивно, постараюсь изложить основные шаги, которые необходимо сделать для того, что бы обзавестись личным блогом на небезизвестном ресурсе.

#### Шаг 1. Хостим статику на github

Для этого нам потребуются аккаунт на [github](https://github.com/) и базовые навыки работы с [git](https://git-scm.com/). К слову сказать, все ниже изложенное можно проделать и для конкурирующего сервиса [gitlab](https://gitlab.com/), - где кому больше нравится.

Далее, нужно просто создать проект, назвав его:  <логин>.github.io, например kostenkoserg.github.io

![github pages project screenshot](/ru/img/my_github_srcshot.png)

В принципе, на этом вся подготовительная рабобта для хостинга статики и завершена. Теперь клонируем проект себе (пока пустой), создаём index.html и пушим в репозиторий:

```
$ git clone https://github.com/kostenkoserg/kostenkoserg.github.io.git
$ cd kostenkoserg.github.io
$ echo "Hello World!"
$ git commit -m "my first github page"
$ git push
```

Все! Страничка доступна по https://kostenkoserg.github.io

![first_github_page](/ru/img/first_github_page.png)
По желанию, к сайту можно подвязать уже существующий домен, если по каким-либо соображениям .github.io не подходит. Для этого нужно

* Добавить ``A`` записи в настройках DNS провайдера с GitHub ипишниками
* В настройках проекта на  GitHub указать DNS имя



#### Шаг 2. Генерация статического сайта с помощью Jbake

[Jbake](https://jbake.org/) - это проект, с открытым исходным кодом, для генерации статических сайтов. Для Jbake доступна интеграция с  Gradle и Maven, из коробки поддержка Bootstrap и прозрачная интеграция с другими CSS фреймворками, а так же поддержка Freemarker, Groovy, Thymeleaf и Jade в качестве шаблонов.

Для начала работы с Jbake, качаем дистрибутив с [сайта проекта](https://jbake.org/download.html) и распаковываем архив куда-то себе. После чего генерируем структуру своего сайта:

```
$ cd myblog
$ /opt/jbake/bin/jbake -i
```

В результате получаем следующую структуру каталогов и немного тестового контента:
```
├── assets
│   ├── css
│   │   ├── asciidoctor.css
│   │   ├── base.css
│   │   ├── bootstrap.min.css
│   │   └── prettify.css
│   ├── favicon.ico
│   ├── fonts
│   │   ├── ...
│   └── js
│       ├── bootstrap.min.js
│       ├── html5shiv.min.js
│       ├── jquery-1.11.1.min.js
│       └── prettify.js
├── content
│   ├── about.html
│   └── blog
│       └── 2013
│           ├── first-post.html
│           ├── second-post.md
│           └── third-post.adoc
├── jbake.properties
└── templates
    ├── archive.ftl
    ├── feed.ftl
    ├── footer.ftl
    ├── header.ftl
    ├── index.ftl
    ├── menu.ftl
    ├── page.ftl
    ├── post.ftl
    ├── sitemap.ftl
    └── tags.ftl
```

Теперь генерируем сам сайт:

```
/opt/jbake/bin/jbake -b
```
В результате чего получим каталог ```output``` с нашим статическим сайтом.
Проверить, что получилось можно по http://localhost:8820/, запустив всторенный сервер

```
/opt/jbake/bin/jbake -s
```
![jbake_default_site](/ru/img/jbake_default_site.png)

Всё! наш статический сайт готов! Для полноценного ведения блога, теперь достаточно отредактировать содержимое каталога ```content```, перегенерировать сайт и запушить полученный ```output``` в, созданный на первом шаге, github репозиторий.

Jbake поддерживает несколько форматов контента: HTML, Markdown, AsciiDoc, - что позволяет вести свой сайт, используя любой текстовый редактор. Я использую [Atom](https://atom.io/) и [Markdown](https://www.markdownguide.org/basic-syntax/).
