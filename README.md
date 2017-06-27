# rails-pg-docker

Dockerizing a Rails Application

Rails Development with Docker

Quickstart guide to show you how to use Docker Compose to set up and run a Rails/PostgreSQL app. 

This repo consists of: 

# Dockerfile

Docker applications are configured via a Dockerfile, which defines how the container is built. Since your app is going to run inside a Docker container containing all of its dependencies, you’ll need to define exactly what needs to be included in the container. This is done using a file called Dockerfile, we are going to be basing our image on the official Alpine Linux-based Ruby image.

Many images are readily available, and you can search for a suitable base image at the Docker Hub. We are using ruby:2.4.1-alpine base image. That’ll put your application code inside an image that will build a container with Ruby, Bundler and all your dependencies inside it. 

```
# Dockerfile
FROM ruby:2.4.1-alpine
# Install dependencies.
RUN apk add --update --no-cache \
      build-base \
      nodejs \
      tzdata \
      libxml2-dev \
      libxslt-dev \
      postgresql-dev \
      imagemagick
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
RUN bundle update && bundle install

# Everything up to here was cached. This includes the bundle install, unless
# the Gemfiles changed. Now copy the app into the image.
ADD . $APP_HOME
```

After adding the above file as Dockerfile to your repository, we can now build the container and start running commands with it. We specify a tag via the -t option, so we can reference the container later on.

```
docker build -t demo .
docker run -it demo "bundle exec rake test"
docker run -itP demo
```

- Here are some explanations for the commands above:
docker run runs tasks in a Docker container. This is most commonly used for one-off tasks but is also very helpful in development.
- The -P option causes all ports defined in the Dockerfile to be exposed to unprivileged ports on the host and thus be accessible from the outside.
- If we don’t specify a command to run on the command line, the command defined by the CMD setting will be run instead.

Now that you’ve written the Dockerfile for your application image, you need to put together the puzzle pieces of your application, for instance your database.

If you have multiple Rails applications that you're working on, you can just copy the Dockerfile and docker-comopse.yml, and as long as you change 3001 in the web container's ports configuration to something else, you'll never run into any port conflicts when trying to run multiple apps at the same time.

# Gemfile
A Gemfile which just loads Rails. It’ll be overwritten in a moment by rails new.

# Commands
```
docker-compose run --rm web bundle install

docker-compose run --rm web bundle exec rails new . -d postgresql
```

Note: Be sure to overwrite the Gemfile when prompted to do so.

# Connecting to services (the database)

By default, Rails expects a database to be running on localhost - so you need to point it at the db container instead. You also need to change the database and username to align with the defaults set by the postgres image.

Replace the contents of config/database.yml with the following:
```ruby
default: &default
  adapter: postgresql
  encoding: unicode
  host: db
  username: postgres
  password:
  pool: 5
  
  adapter: postgresql 
  encoding: unicode 
  pool: 5 
  timeout: 5000 
  username: postgres 
  host: postgres
  port: 5432
  
development:
  <<: *default
  database: myapp_development


test:
  <<: *default
  database: myapp_test
  
```
# Starting Up
Now that your Dockerfile and docker-compose.yml are written, and your application is configured to connect to the containered services, all that’s left before you can start your application.

```
docker-compose run --rm web bundle


docker-compose run --rm web bin/rake db:create db:setup

docker-compose up
```

# View the Rails welcome page!
That’s it. Your app should now be running on port 3002 on your Docker daemon.

On Docker for Mac and Docker for Windows, go to http://localhost:3002 on a web browser to see the Rails Welcome.

# Stop the application
To stop the application, run 
```
docker-compose down 
```
in your project directory. You can use the same terminal window in which you started the database, or another one where you have access to a command prompt. This is a clean way to stop the application.

# Quick example with a task model

```
docker-compose run --rm web bin/rails g scaffold task title:string notes:string due:datetime completion:integer  

docker-compose run --rm web bin/rake db:migrate

docker-compose up

```

Go to http://localhost:3002/tasks on a web browser!.

