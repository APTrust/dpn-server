# Minimal configuration for building a DPN-Server test instance.
# There are a few customizations for running it in your environment
# - Tag your image after the build
# -  docker images
# -  docker tag <IMAGE ID> dpcolar/dpn-server:v2
# - Run parameters
# -  docker run -it --net=host --name test dpcolar/dpn-server:v2.1 /bin/bash
# -  --net=host makes the instance visible on your local network
# -  any service locked down to localhost will need to be modified to allow the host IP
# -  you'll get a bash prompt to make changes in your local environment
# -  type exit to close the shell
#
# -  if you want to preserve changes do a commit
# -  docker ps -l
# -  docker commit <CONTAINER ID> dpcolar/dpn-server:v2
#
#FROM ubuntu
FROM ruby:2.3.0
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
## Set your Build Tag
RUN git clone -b impersonate-config-fix https://<your token>:x-oauth-basic@github.com/dpn-admin/dpn-server.git /dpn-server
WORKDIR /dpn-server
## Gemfile.local should be in your CWD
ADD Gemfile.local /dpn-server/Gemfile.local
RUN bundle install --path .bundle
RUN bundle exec rake config
RUN bundle exec rake db:setup
RUN bundle exec rspec
ADD . /dpn-server
EXPOSE 80
EXPOSE 443
