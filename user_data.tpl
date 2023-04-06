#!/bin/bash
cat <<EOF > /etc/systemd/system/webapp.service
[Unit]
Description=Webapp Service
After=network.target

[Service]
Environment="NODE_ENV=${NODE_ENV}"
Environment="PORT=${PORT}"
Environment="DIALECT=${DIALECT}"
Environment="HOST=${rds_host}"
Environment="USERNAME=${rds_username}"
Environment="PASSWORD=${rds_password}"
Environment="DB_NAME=${rds_db_name}"
Environment="S3_BUCKET_NAME=${s3_bucket_name}"
Environment="REGION=${region}"

Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/webapp
ExecStart=/usr/bin/node server.js
Restart=on-failure
SyslogIdentifier=webapp

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
EOF

sudo systemctl daemon-reload
sudo systemctl start webapp.service
sudo systemctl enable webapp.service
sudo systemctl status webapp.service
journalctl -u webapp.service

# Setting up ngnix for reverse-proxy
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y

ENVIRONMENT=${profile}
if [ "$ENVIRONMENT" == "dev" ]; then
  server_name="${dev_A_record_name}"
else
  server_name="${prod_A_record_name}"
fi

cat <<EOF > /etc/nginx/conf.d/reverse-proxy.conf
server { 
  listen 80; 
  server_name $server_name; 
  location / { 
    proxy_pass http://localhost:3000;
  }
}
EOF
sudo systemctl reload nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/config.json
