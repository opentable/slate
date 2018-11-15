FROM docker.otenv.com/ot-java:9-latest

RUN apt-get update
RUN apt-get install -yq ruby ruby-dev build-essential
RUN gem install --no-ri --no-rdoc bundler
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN cd /app; bundle update; bundle install
ADD . /app

ADD http://artifactory.otenv.com:8081/artifactory/internal/com/opentable/discovery-announcer-standalone/1.0.3/discovery-announcer-standalone-1.0.3.jar /var/lib/discovery/discovery-announcer-standalone-1.0.3.jar

WORKDIR /app

CMD ["/usr/bin/supervisord"]
