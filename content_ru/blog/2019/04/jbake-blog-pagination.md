title=Пагинация блога на JBake date=2019-04-10 type=post tags=JBake status=published


Чтобы включить поддержку пагинации в своем блоге на основе JBake, вам необходимо указать следующие свойства в файле `jbake.properties`: 

```java
index.paginate=true
index.posts_per_page=5
```

После этого, JBake сгенерирует подкаталоги `2,3,4...` для вашего `index.html`. Далее, вам нужно обновить шаблон `index`, что бы сгенерировать необходимое количество постов на каждой странице и обеспечить кнопки перехода для "предыдущей", "следующей".

Ниже, я покажу вам шаблон FreeMarker с поддержкой пагинации, который я использую для этого блога.

```java
<#include "header.ftl">
	<#include "menu.ftl">
	<#list posts as post>
  		<#if (post.status == "published"  && post?index >= (currentPageNumber-1) * config.index_posts_per_page?eval && post?index < currentPageNumber * config.index_posts_per_page?eval)>
				<a href="${post.uri}"><h1><#escape x as x?xml>${post.title}</#escape></h1></a>
				<p>${post.date?string("dd MMMM yyyy")}</p>
  			<p>${post.body}</p>
				<hr/>
  		</#if>
  	</#list>
		<ul class="pager">
			<#if (currentPageNumber > 1)><li class="previous"><a href="${config.site_host}/${(currentPageNumber==2)?then('', currentPageNumber-1)}">Previous</a></li></#if>
			<li>Page: ${currentPageNumber}/${numberOfPages} (<a href="${content.rootpath}${config.archive_file}">archive</a>)</li>
			<#if (currentPageNumber < numberOfPages)><li class="next"><a href="${config.site_host}/${currentPageNumber + 1}">Next</a></li></#if>
		</ul>
<#include "footer.ftl">
```

Код этого блога доступен на [GitHub](https://github.com/kostenkoserg/kostenko.blog.src)
