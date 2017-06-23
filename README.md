# rails-pg-docker
Rails Development with Docker

Quickstart guide to show you how to use Docker Compose to set up and run a Rails/PostgreSQL app. 

This repo consists of: 

# Dockerfile
Since your app is going to run inside a Docker container containing all of its dependencies, you’ll need to define exactly what needs to be included in the container. This is done using a file called Dockerfile, we are going to be basing our image on the official Alpine Linux-based Ruby image.

That’ll put your application code inside an image that will build a container with Ruby, Bundler and all your dependencies inside it. 

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

docker-compose run --rm web bin/rake db:setup
```
