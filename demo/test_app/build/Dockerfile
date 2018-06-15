FROM ruby:2.3

RUN gem install -N activesupport --version 4.2.7.1
RUN gem install -N conjur-api:"< 5.0" conjur-cli:"< 6.0" sinatra

COPY test_app.rb usr/src/test_app.rb

env PORT 80

CMD [ "ruby", "/usr/src/test_app.rb" ]