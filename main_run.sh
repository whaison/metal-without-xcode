#!/bin/bash
#http://www.task-notes.com/entry/20150214/1423882800
#dev/work  ← dirname $0 の結果
#やってる事は単純でcdを使ってディレクトリを移動した後に
cd $(dirname $0) 
echo cd $(dirname $0) 
#make で Makefile の依存関係に従って main ファイルをコンパイルします。
make
echo make

#pwdコマンドを使うことです。これはカレントディレクトリの絶対パスを取得してくれます。
mydir=`pwd`
echo $mydir
echo $mydir"/"main ; 
#main ファイルを実行します。
# $mydir"/"main ; exit;
 $mydir"/"main ; 
#cd $mydir
