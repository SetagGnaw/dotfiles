# prometheus
promstart(){
    pwd
    prometheus --config.file=./prometheus.yml 
}
promrestart(){
    # curl -X POST http://localhost:9090/-/reload
    kill -HUP $(pgrep prometheus)
}
promkill(){
    pkill prometheus
}
promstatus(){
    pgrep prometheus
}


# alertmanager
alertstart(){
    alertmanager --config.file=./alertmanager.yml 
}
alertrestart(){
    pkill alertmanager && alertmanager --config.file=./alertmanager.yml 
}
alertstatus(){
    pgrep alertmanager
}
# promtool check rules prometheus.rules.yml;
# promtool check config prometheus.yml


# node exporter
nodestart_helper(){
    cd /Users/gateswang/Programming/Learning/prometheus/node_exporter
    ./node_exporter --web.listen-address 127.0.0.1:8081 2>&1 &
    ./node_exporter --web.listen-address 127.0.0.1:8082 2>&1 &
    ./node_exporter --web.listen-address 127.0.0.1:9100 2>&1 &
}
nodestart(){
    nodestart_helper 2>&1 &
}
nodekill(){
    pkill node_exporter
}
nodestatus(){
    pgrep node_exporter
}

