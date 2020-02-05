title=JBake blog pagination
date=2019-04-10
type=post
tags=jbake
status=published
~~~~~~

To enable pagintation support on your JBake based blog you need to provide next properties in your `jbake.properties` file:

```java
index.paginate=true
index.posts_per_page=5
```

After that JBake will generate subdirectories `2,3,4...` for your `index.html`. Next, you need to update `index` template to generate necessary count of posts per each index page and provide "previous","next" navigation buttons.

Below, I will show you freemarker template with pagination support, that I am using for this blog

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

Blog sources available on [GitHub](https://github.com/kostenkoserg/kostenko.blog.src)
