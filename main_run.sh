#!/bin/bash
#http://www.task-notes.com/entry/20150214/1423882800
#dev/work  ← dirname $0 の結果
#やってる事は単純でcdを使ってディレクトリを移動した後に
cd $(dirname $0) 
#pwdコマンドを使うことです。これはカレントディレクトリの絶対パスを取得してくれます。
mydir=`pwd`
echo $mydir
 $mydir"/"main ; exit;
#cd $mydir
