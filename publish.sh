#!/bin/sh

cd target
server="172.16.1.1";

for file in $(ls -rt *.jar|tail -1);
do
    scp  ${file} root@${server}:/dashu/application/ ;
    echo ${file}
done