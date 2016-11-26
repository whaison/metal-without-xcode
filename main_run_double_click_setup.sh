# そのまま実行しようとすると権限で弾かれる

#./main_run.sh

#-> zsh: permission denied: ./hello.sh

# 実行権限を与える

chmod +x main_run.sh
./main_run.sh

# -> hello world!