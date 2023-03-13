#!/bin/bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

sudo apt update
sudo apt-get install apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

export JAVA_HOME=/usr/share/elasticsearch/jdk && echo export JAVA_HOME=/usr/share/elasticsearch/jdk >>/etc/bash.bashrc

sudo apt update
sudo apt-get install elasticsearch | tee elasticsearch-info.txt
sudo apt -qq install kibana filebeat auditbeat -y
sudo apt install python3-pip -y
pip install elasticsearch-curator

cat >/etc/cron.daily/curator <<EOF
#!/bin/sh
curator_cli --host 10.10.7.105 delete_indices --filter_list '{"filtertype": "age", "source": "name", "timestring": "%Y.%m.%d", "unit": "days", "unit_count": 1, "direction": "older"}'  > /dev/null 2>&1
EOF
chmod +x /etc/cron.daily/curator

echo "[!] Generating Passwords and tokens!"
echo 'y' | /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node


# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
sudo systemctl enable kibana.service
sudo systemctl start kibana.service
