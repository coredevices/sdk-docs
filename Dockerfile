FROM ruby:2.2.9
COPY docker/sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y --force-yes nodejs
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]