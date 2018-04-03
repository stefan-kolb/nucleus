FROM ruby:2.4

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock nucleus.gemspec ./
RUN bundle install

COPY . .

ENV RACK_ENV=development
EXPOSE 9292

CMD ["rackup", "-s", "thin", "--host", "0.0.0.0", "config.ru"]
