#!/bin/bash

# Helper script to bake the blog
# Author: kostenko

export PATH="/opt/jbake/bin":$PATH
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
