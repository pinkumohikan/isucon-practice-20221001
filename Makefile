.PHONY: *

gogo: stop-services build truncate-logs sync-sql start-services bench

build:
	cd webapp/go && go build -o isuconquest

stop-services:
	sudo systemctl stop nginx
	sudo systemctl stop isuconquest.go.service
	ssh isucon-app2 "sudo systemctl stop mysql"
	ssh isucon-app3 "sudo systemctl stop mysql"
	ssh isucon-app4 "sudo systemctl stop mysql"
	ssh isucon-app5 "sudo systemctl stop mysql"

start-services:
	ssh isucon-app2 "sudo systemctl start mysql"
	ssh isucon-app3 "sudo systemctl start mysql"
	ssh isucon-app4 "sudo systemctl start mysql"
	ssh isucon-app5 "sudo systemctl start mysql"
	sleep 5
	sudo systemctl start isuconquest.go.service
	sudo systemctl start nginx

truncate-logs: truncate-db-logs
	sudo truncate --size 0 /var/log/nginx/access.log
	sudo truncate --size 0 /var/log/nginx/error.log
	ssh isucon-app5 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"
	ssh isucon-app5 "sudo chmod 777 /var/log/mysql/mysql-slow.log"
	sudo journalctl --vacuum-size=1K

truncate-db-logs:
	ssh isucon-app2 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"
	ssh isucon-app2 "sudo chmod 777 /var/log/mysql/mysql-slow.log"
	ssh isucon-app3 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"
	ssh isucon-app3 "sudo chmod 777 /var/log/mysql/mysql-slow.log"
	ssh isucon-app4 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"
	ssh isucon-app4 "sudo chmod 777 /var/log/mysql/mysql-slow.log"
	ssh isucon-app5 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"
	ssh isucon-app5 "sudo chmod 777 /var/log/mysql/mysql-slow.log"

sync-sql:
	scp -C wepapp/sql isucon-app2:/home/isucon/webapp/
	scp -C wepapp/sql isucon-app3:/home/isucon/webapp/
	scp -C wepapp/sql isucon-app4:/home/isucon/webapp/
	scp -C wepapp/sql isucon-app5:/home/isucon/webapp/

bench:
	ssh isucon-bench "export ISUXBENCH_TARGET=172.31.13.141 &&  ./bin/benchmarker --stage=prod --request-timeout=10s --initialize-request-timeout=60s"

kataribe:
	sudo cat /var/log/nginx/access.log | ./kataribe -conf kataribe.toml | grep --after-context 20 "Top 20 Sort By Total"
