# Dockerfile
FROM ruby:2.4.1-alpine
# Install dependencies.
RUN apk add --update --no-cache \
      build-base \
      nodejs \
      tzdata \
      libxml2-dev \
      libxslt-dev \
      postgresql-dev
RUN bundle config build.nokogiri --use-system-libraries
# Setup app directory.
ENV APP_HOME /myapp
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
# Copy the Gemfile and Gemfile.lock into the image and install gems before the
# project is copied to avoid do bundle install every time some project file
# change.
ADD Gemfile $APP_HOME/
ADD Gemfile.lock $APP_HOME/
RUN bundle install && bunlde update

# Everything up to here was cached. This includes the bundle install, unless
# the Gemfiles changed. Now copy the app into the image.
ADD . $APP_HOME
