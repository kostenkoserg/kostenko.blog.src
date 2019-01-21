#!/bin/bash
#
# Helper script to bake the blog
#
# Author: kostenko

read -p "Press [Enter] key to regenerate blog"

export PATH="/opt/jbake-2.6.3-bin/bin":$PATH

# Remove previously builded content
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
