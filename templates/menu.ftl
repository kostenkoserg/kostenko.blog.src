	<!-- Fixed navbar -->
    <div class="navbar navbar-default navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <b><a class="navbar-brand" href="${content.rootpath}index.html">Sergii Kostenko's Blog</a></b>
        </div>
        <div class="navbar-collapse collapse">
          <ul class="nav navbar-nav">
            <li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>about.html">About</a></li>
						<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>resume.html">Resume</a></li>
            <li class="dropdown">
              <a href="#" class="dropdown-toggle" data-toggle="dropdown">Tags <b class="caret"></b></a>
              <ul class="dropdown-menu">
									<#list tags as tag>
										<li><a href="${content.rootpath}${tag.uri}">${tag.name}</a></li>
									</#list>
								</ul>
						</li>
          </ul>
					<!-- switch language -->
					<ul class="nav navbar-nav navbar-right">
						<li><a href="/">en</a></li>
						<li><a href="/ru">ru</a></li>
						<li><a  class="icon-rss" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>${config.feed_file}"></a></li>
					</ul>
        </div><!--/.nav-collapse -->
      </div>
    </div>
    <div class="container">
