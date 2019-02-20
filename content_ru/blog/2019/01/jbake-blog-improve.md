title= Jbake. Добавляем теги, поддержку нескольких языков и аналитику
date=2019-01-19
type=post
tags=JBake
status=published
~~~~~~
#### 1. Теги

Jbake поддерживает работу с тегами из коробки и при использовании тегов в описании будет генерироваться отдельная страница под каждый тег. Достаточно отредактировать параметр ``render.tags`` в конфигурационном файле ``jbake.properties``
```
render.tags=true
```

Теперь в зависимости от того, где мы хотим разместить список тегов, редактируем соответствующий темплейт. Для этого блога я использую freemarker и решил вывести теги в меню в виде выпадающего списка. Соответственно, изменив  ``menu.ftl`, как показано ниже:

```
  <ul class="dropdown-menu">
      <#list tags as tag>
        <li><a href="${content.rootpath}${tag.uri}">${tag.name}</a></li>
      </#list>
  </ul>
```
Готово!

#### 2. Контент на нескольких языках

К сожалению, Jbake пока не поддерживает мультиязычные блоги на уровне метаданных и для обеспечения этой функциональности мне пришлость проделать несколько нехитрых упражнений. Сперва, я просто хотел сделать полную копию с другим языком контента, но в случае любых изменений для шаблонов, скриптов, изображений - правки пришлось бы делать дважды. Что не есть хорошо.

Вместо этого я просто создал каталог ``content_ru`` в корне проекта.

```
├── assets  
├── content  
├── content_ru
├── templates
├── jbake.properties
├── README.md  
```

К счастью, в ``jbake.properies`` есть возможность установить каталог контента, который будет использован при генерации, что позволяет держать несколько директорий в проекте.  Теперь сгенерировать мультиязычный блог можно используя скрипт:

bakeblog.sh:
```
#!/bin/bash

# Helper script to bake the blog
# Author: kostenko

export PATH="/opt/jbake-2.6.3-bin/bin":$PATH
rm -R ./output
# Building en version
export JBAKE_OPTS="-Duser.language=EN"
jbake -b
# Build ru version
export JBAKE_OPTS="-Duser.language=RU"
mv jbake.properties jbake.properties.orig
cat jbake.properties.orig >> jbake.properties
echo "content.folder=content_ru" >> jbake.properties
jbake -b . output/ru
# cleanup
rm jbake.properties
mv jbake.properties.orig jbake.properties
```

Добавим возможность переключения языков в меню:

```
<!-- switch language -->
<ul class="nav navbar-nav navbar-right">
  <li><a href="/">en</a></li>
  <li><a href="/ru">ru</a></li>
</ul>
```

На этом все!


#### 3. Аналитика

Для того что бы подключить [Google analytics](https://analytics.google.com) нужно выполнить несколько простых шагов

* Зарегестировать ресурс в GA
* Получить сгенерированный GA фрагмент кода
* Вставить этот код в ``header.ftl`` первой строкой блока ``<HEAD>``.

```
<!-- Global site tag (gtag.js) - Google Analytics -->
<head>
  <script async src="https://www.googletagmanager.com/gtag/js?id=<YOUR_GA_ID>"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', '<YOUR_GA_ID>');
  </script>
  ...
```


P.S. При желании к блогу можно подключить возможность оставлять комментарии, используя например [Disqus](https://disqus.com/).
P.P.S. Код этого блога доступен на [GitHub](https://github.com/kostenkoserg/kostenko.blog.src)
