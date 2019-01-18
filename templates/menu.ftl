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
          <a class="navbar-brand" href="${content.rootpath}index.html">Sergii Kostenko's blog</a>
        </div>
        <div class="navbar-collapse collapse">
          <ul class="nav navbar-nav">
            <li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>about.html">About</a></li>
						<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>about.html">Resume</a></li>
            <li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>${config.feed_file}">Feed</a></li>
            <li class="dropdown">
              <a href="#" class="dropdown-toggle" data-toggle="dropdown">Tags <b class="caret"></b></a>
              <ul class="dropdown-menu">
									<#list tags as tag>
										<li><a href="${content.rootpath}${tag.uri}">${tag.name}</a></li>
									</#list>
								</ul>
						</li>
          </ul>
        </div><!--/.nav-collapse -->
      </div>
    </div>
    <div class="container">
