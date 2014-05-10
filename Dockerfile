#Kibana

FROM dockerfile/java
 
#Prevent daemon start during install
RUN	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && \
	mkdir -p /var/log/supervisor
CMD ["/usr/bin/supervisord", "-n"]

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server && \
	mkdir /var/run/sshd && \
	echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less ntp net-tools inetutils-ping curl git telnet

#ElasticSearch
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.7.tar.gz && \
    tar xf elasticsearch-*.tar.gz && \
    rm elasticsearch-*.tar.gz && \
    mv elasticsearch-* /opt/elasticsearch

#Kibana
RUN wget https://download.elasticsearch.org/kibana/kibana/kibana-3.0.0milestone4.tar.gz && \
    tar xvf kibana-*.tar.gz && \
    rm -f kibana-*.tar.gz && \
    mv kibana-* /opt/kibana

#NGINX
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-software-properties && \
    add-apt-repository ppa:nginx/stable && \
    echo 'deb http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list && \
    curl http://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

#Logstash
RUN wget https://download.elasticsearch.org/logstash/logstash/logstash-1.2.2-flatjar.jar && \
    mkdir /opt/logstash && \
    mv logstash*.jar /opt/logstash
#java -jar logstash-1.2.2-flatjar.jar agent -f docker-kibana/logstash.conf
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libzmq-dev

#Configuration
ADD ./ /docker-kibana
RUN cd /docker-kibana && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.saved && \
    cp nginx.conf /etc/nginx/nginx.conf && \
    sed -i -e 's|elasticsearch:.*|elasticsearch: "http://"+window.location.hostname + ":" + window.location.port,|' /opt/kibana/config.js && \
    cp supervisord-kibana.conf /etc/supervisor/conf.d

#80=ngnx, 9200=elasticsearch, 49021=logstash/zeromq
EXPOSE 22 80 9200 49021
