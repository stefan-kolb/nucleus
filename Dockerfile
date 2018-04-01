FROM ruby:2.4

WORKDIR /usr/src/app

COPY . .
RUN bundle install

EXPOSE 9292

CMD ["ruby", "bin/nucleus"]
