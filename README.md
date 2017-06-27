## Quickstart: Compose and Rails

Dockerizing a Rails Application

Rails Development with Docker

Quickstart guide to show you how to use Docker Compose to set up and run a Rails/PostgreSQL app. 

This repo consists of: 

# Define the project
Start by setting up the four files you’ll need to build the app. First, since your app is going to run inside a Docker container containing all of its dependencies, you’ll need to define exactly what needs to be included in the container. This is done using a file called Dockerfile. 

We are going to be basing our image on the official Alpine Linux-based Ruby image.

Many images are readily available, and you can search for a suitable base image at the Docker Hub. We are using ruby:2.4.1-alpine base image.  

### 1. Dockerfile
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
That’ll put your application code inside an image that will build a container with Ruby, Bundler and all your dependencies inside it.

We now have our Rails application running inside a Docker container, but how do we actually access it from our computer? We will use docker ps, a handy tool to list running Docker processes as well as additional information about them.

Now that you’ve written the Dockerfile for your application image, you need to put together the puzzle pieces of your application, for instance your database.

If you have multiple Rails applications that you're working on, you can just copy the Dockerfile and docker-comopse.yml, and as long as you change 3001 in the web container's ports configuration to something else, you'll never run into any port conflicts when trying to run multiple apps at the same time.

Next, create a bootstrap Gemfile which just loads Rails. It’ll be overwritten in a moment by rails new.

### 2. Gemfile
```
source 'https://rubygems.org'
gem 'rails', '5.0.0.1'
```

You’ll need an empty Gemfile.lock in order to build our Dockerfile.

### 3. Gemfile.lock
```
touch Gemfile.lock
```

Finally, docker-compose.yml is where the magic happens. This file describes the services that comprise your app (a database and a web app), how to get each one’s Docker image (the database just runs on a pre-made PostgreSQL image, and the web app is built from the current directory), and the configuration needed to link them together and expose the web app’s port.

### 4. docker-compose.yml
```
version: '2'
services:
  db:
    image: postgres
    volumes:
      - ../sqldumps:/sqldumps
  web:
    # builds the Docker image using the Dockerfile
    build: .
    # Now that we have our image, run it
    command: bin/rails server --port 3000 --binding 0.0.0.0
    volumes:
      - .:/myapp
    ports:
      - "3002:3000"
    links:
      - db:postgres
```

# Build the project

Now that your Dockerfile and docker-compose.yml are written, and your application is configured to connect to the containered services, all that’s left before you can start your application.

With those four files in place, you can now generate the Rails skeleton app using docker-compose run:

```
docker-compose run --rm web rails new . -d postgresql 
```
Note: Be sure to overwrite the Gemfile when prompted to do so.

First, Compose will build the image for the web service using the Dockerfile. Then it will run rails new inside a new container, using that image. Once it’s done, you should have generated a fresh app.

Now that you’ve got a new Gemfile, you need to build the image again. (This, and changes to the Gemfile or the Dockerfile, should be the only times you’ll need to rebuild.)

```
docker-compose build
```

# Connect the database
The app is now bootable, but you’re not quite there yet. By default, Rails expects a database to be running on localhost - so you need to point it at the db container instead. You also need to change the database and username to align with the defaults set by the postgres image.

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

production:
  <<: *default
  database: myapp_production
```

You can now boot the app with docker-compose up:

```
docker-compose up
```

Finally, you need to create the database. In another terminal, run:

```
docker-compose run web rake db:create
```

# View the Rails welcome page!
That’s it. Your app should now be running on port 3002 on your Docker daemon.

On Docker for Mac and Docker for Windows, go to http://localhost:3002 on a web browser to see the Rails Welcome.

# Stop the application
To stop the application, run  ```docker-compose down``` in your project directory. You can use the same terminal window in which you started the database, or another one where you have access to a command prompt. This is a clean way to stop the application.

You can also stop the application with Ctrl-C in the same shell in which you executed the docker-compose up. If you stop the app this way, and attempt to restart it, you might get the following error:

```
web_1 | A server is already
running. Check /myapp/tmp/pids/server.pid.
```

To resolve this, delete the file tmp/pids/server.pid, and then re-start the application with ```docker-compose up```.

# Restart the application
To restart the application:

### 1. Run ```docker-compose up``` in the project directory.
### 2. Run this command in another terminal to restart the database: ```docker-compose run web rake db:create```

# Rebuild the application
If you make changes to the Gemfile or the Compose file to try out some different configurations, you will need to rebuild. Some changes will require only ```docker-compose up --build```, but a full rebuild requires a re-run of ```docker-compose run web bundle install``` to sync changes in the ```Gemfile.lock``` to the host, followed by ```docker-compose up --build```.

Here is an example of the first case, where a full rebuild is not necessary. Suppose you simply want to change the exposed port on the local host from ```3000``` in our first example to ```3002```. Make the change to the Compose file to expose port 3000 on the container through a new port, 3001, on the host, and save the changes:

```
ports: - "3001:3000"
```
Now, rebuild and restart the app with ```docker-compose up --build```, then restart the database: ```docker-compose run web rake db:create```.

Inside the container, your app is running on the same port as before 3000, but the Rails Welcome is now available on ```http://localhost:3002``` on your local host.



# Quick example with a task model

```
docker-compose run --rm web rails g scaffold task title:string notes:string due:datetime completion:integer  

docker-compose run --rm web rake db:migrate

docker-compose up

```

Go to http://localhost:3002/tasks on a web browser!.

