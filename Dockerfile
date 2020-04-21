FROM docker.otenv.com/ubuntu:latest

RUN apt-get update
RUN apt-get install -yq ruby ruby-dev build-essential
RUN gem install bundler

ADD Gemfile /app/Gemfile
ADD discovery-wrapper /app/discovery-wrapper
RUN cd /app; bundle install
ADD . /app


WORKDIR /app

RUN chmod +x discovery-wrapper

CMD ["/bin/sh", "-c", "./discovery-wrapper -t slate -s http bundle exec middleman server -p ${PORT0}"]