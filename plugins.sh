#! /bin/bash

# Parse a support-core plugin -style txt file as specification for jenkins plugins to be installed
# in the reference directory, so user can define a derived Docker image with just :
#
# FROM jenkins
# COPY plugins.txt /plugins.txt
# RUN /usr/local/bin/plugins.sh /plugins.txt
#

REF=/usr/share/jenkins/ref/plugins
mkdir -p $REF

if [ -z "$JENKINS_UC_DOWNLOAD" ]; then
    JENKINS_UC_DOWNLOAD=$JENKINS_UC/download
fi

get_plugin() {
    curl -L ${JENKINS_UC_DOWNLOAD}/plugins/${plugin[0]}/${plugin[1]}/${plugin[0]}.hpi -o $REF/${plugin[0]}.jpi;
    echo "=> $(ls -l $REF/${plugin[0]}.jpi)"
    if file $REF/${plugin[0]}.jpi | grep -v Zip; then
        echo "Failed to get jpi"
        return 1
    fi
    unzip -qqt $REF/${plugin[0]}.jpi
    return 0
}

while read spec || [ -n "$spec" ]; do
    plugin=(${spec//:/ });
    [[ ${plugin[0]} =~ ^# ]] && continue
    [[ ${plugin[0]} =~ ^\s*$ ]] && continue
    [[ -z ${plugin[1]} ]] && plugin[1]="latest"
    plugin=(${spec//:/ })
    echo "Downloading ${plugin[0]} : ${plugin[1]}"
    if ! get_plugin; then
        echo "Failed, retrying"
        if ! get_plugin; then
            echo "Failed again, exiting"
            exit 1
        fi
    fi
done  < $1

