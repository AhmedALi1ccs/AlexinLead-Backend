FROM ruby:3.1.2

WORKDIR /app

RUN apt-get update && apt-get install -y postgresql-client nodejs

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN echo "6bbbed9bb8d79f5b0c7281106fc48149" > config/master.key

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]