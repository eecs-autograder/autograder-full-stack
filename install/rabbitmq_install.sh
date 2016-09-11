wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc |
        sudo apt-key add -
echo 'deb http://www.rabbitmq.com/debian/ testing main' |
        sudo tee /etc/apt/sources.list.d/rabbitmq.list
sudo apt-get update
sudo apt-get install -y rabbitmq-server
sudo apt-get install -y erlang-ssl

sudo rabbitmq-plugins enable rabbitmq_management

sudo rabbitmqctl add_user jameslp jameslp
sudo rabbitmqctl set_user_tags jameslp administrator
sudo rabbitmqctl set_permissions -p / jameslp ".*" ".*" ".*"

test -f /var/lib/rabbitmq/.erlang.cookie && sudo cat $_ && printf "\nErlang cookie found in $_\n"
test -f $HOME/.erlang.cookie && cat $_ && printf "\nErlang cookie found in $_\n"

