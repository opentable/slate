FROM ruby:2.5.1

RUN apt-get update && apt-get install -y nodejs \
&& apt-get clean && rm -rf /var/lib/apt/lists/*

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
ADD discovery-wrapper /app/discovery-wrapper
RUN cd /app; bundle install
ADD . /app

WORKDIR /app

RUN chmod +x discovery-wrapper

CMD ["./discovery-wrapper", "-t slate", "-s http", "bundle", "exec", "middleman", "server -p %(ENV_PORT0)s"]
