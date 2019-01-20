title= Jbake. Add tags, multilanguage support and analytics
date=2019-01-19
type=post
tags=github, jbake
status=published
~~~~~~
Jbake supports tagging out of the box. It means that engine will generate separate page for each tag. To enable this feature on your blog you need to change ``render.tags`` property in your ``jbake.properties`` file
```
render.tags=true
```
Next  modify template file depends on where you whant to reneder tags. For this blog I am using freemarker templates and made desition to put tags as part of menu bar. So, chages of my ``menu.ftl`` below:

```
  <ul class="dropdown-menu">
      <#list tags as tag>
        <li><a href="${content.rootpath}${tag.uri}">${tag.name}</a></li>
      </#list>
  </ul>
```
That's is it!

Now let's talk about multilanguage support. It is pity, but Jbake does not support blogging in different languages at the same time by default. So, we need a some hacks to do that. First idea  I had was about two the same sites  in different languages. It is not big deal, but in case changes for  templates, assets or images  you will need to do it twice. What is not so good.

Instead of full copy  I did additional directory ``content_ru`` just with content.

```
├── assets  
├── content  
├── content_ru
├── templates
├── jbake.properties
├── README.md  
```

In ``jbake.propeeries`` you can specify which content should be used.

So, I  choosen english as default language and bake my blog in the next way:

bake.sh:
```
$ export JBAKE_OPTS="-Duser.language=EN"
$ bin/jbake -b
change property file with content.folder=content_ru
$ export JBAKE_OPTS="-Duser.language=RU"
$ jbake -b . output/ru
```

Now let’s add to the menu bar links to choose language:
```
<!-- switch language -->
<ul class="nav navbar-nav navbar-right">
  <li><a href="/">en</a></li>
  <li><a href="/ru">ru</a></li>
</ul>
```
Done!
