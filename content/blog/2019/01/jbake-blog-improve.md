title= Jbake. Add tags, multi languages support and analytics
date=2019-01-19
type=post
tags=jbake
status=published
~~~~~~
#### 1. Tags

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

#### 2. Multi languages

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

In ``jbake.properies`` you can specify which content should be used.

So, I  choosen english as default language and bake my blog in the next way:

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

Now let’s add to the menu bar links to choose language:
```
<!-- switch language -->
<ul class="nav navbar-nav navbar-right">
  <li><a href="/">en</a></li>
  <li><a href="/ru">ru</a></li>
</ul>
```
Done!

#### 3. Analytics

To enable [Google analytics](https://analytics.google.com) functionality on your Jbake based  site, you need to do few simple steps:

* Register your resource on  google analytics
* Get provided by GA code snippet
* Paste provided snippet to your ``header.ftl`` as first block of ``<HEAD>`` section.

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
Congrats! You are ready to blogging!

P.S. If you want to have comments for your posts, - refer to the services like [Disqus](https://disqus.com/) - it is aloso easy to integrate and nice to have for some reasons.
P.P.S. Blog sources available on [GitHub](https://github.com/kostenkoserg/kostenko.blog.src)
