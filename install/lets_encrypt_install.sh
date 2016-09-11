sudo apt install letsencrypt
sudo letsencrypt certonly --standalone -d $(hostname).eecs.umich.edu

crontab -l > tmp_crontab
echo "42  6  * * *   letsencrypt renew" >> tmp_crontab
echo "15 18  * * *   letsencrypt renew" >> tmp_crontab

crontab tmp_crontab
rm tmp_crontab
crontab -l

