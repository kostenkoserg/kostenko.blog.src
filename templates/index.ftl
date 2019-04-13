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
			<#if (currentPageNumber > 1)>
				<li class="previous"><a href="${config.site_host}/${(currentPageNumber==2)?then('', currentPageNumber-1)}">Previous</a></li>
			</#if>
			<li">Page: ${currentPageNumber}/${numberOfPages} (<a href="${content.rootpath}${config.archive_file}">archive</a>)</li>
			<#if (currentPageNumber < numberOfPages)>
				<li class="next"><a href="${config.site_host}/${currentPageNumber + 1}">Next</a></li>
			</#if>
		</ul>
<#include "footer.ftl">
