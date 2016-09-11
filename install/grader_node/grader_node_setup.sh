sudo cp systemd_scripts/ag_media_root_sshfs.service systemd_scripts/postgres_tunnel.service systemd_scripts/redis_tunnel.service systemd_scripts/rabbitmq_tunnel.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable ag_media_root_sshfs.service postgres_tunnel.service redis_tunnel.service rabbitmq_tunnel.service

sudo systemctl start ag_media_root_sshfs.service postgres_tunnel.service redis_tunnel.service rabbitmq_tunnel.service
