# Throttling

[![Travis-CI build status](https://secure.travis-ci.org/kpumuk/throttling.png)](http://travis-ci.org/kpumuk/throttling)

Throttling gem provides basic, but very powerful way to throttle various user actions in your application. Basically you can specify how many times some action could be performed over a specified period(s) of time.

## Installation

Add this line to your application's Gemfile:

    gem 'throttling'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install throttling

## Configuration

You can configure Throttling parameters by accessing attributes of `Throttling` module. Currently it supports only Memcached through `Rails.cache`.

    Throttling.storage = Rails.cache
    Throttling.logger = Rails.logger

Throttling limits could be stored in a configuration file in `config/throttling.yml`. You can also specify another file to read limits from:

    Throttling.limits_config = "#{Rails.root}/config/throttling.yml"

The basic structure of the file is:

    user_signup:
      limit: 20
      period: 3600

    search_requests:
      minutely:
        limit: 300
        period: 600
      hourly:
        limit: 1000
        period: 3600
      daily:
        limit: 10000
        period: 86400

You can also specify limits as a Hash:

    Throttling.limits = {
      :user_signup => {
        :limit  => 20,
        :period => 3600
      },
      :search_requests => {
        :minutely => {
          :limit  => 20,
          :period => 3600
        },
        :hourly => {
          :limit  => 1000,
          :period => 3600
        },
        :daily =>
          :limit  => 10000,
          :period => 86400
        }
      }
    }

You can completely disable throttling by setting `enabled` to `false`:

    Throttling.enabled = false

## Usage

The basic usage of Throttling gem is following:

    Throttling.for(:user_signup).check(:user_id, current_user.id) do
      # Do your stuff here
    end

    if Throttling.for(:user_signup).check(:user_id, current_user.id)
      # Action allowed
    else
      # Action denied
    end

For convenience, there are some simplified methods:

    Throttling.for(:user_signup).check_ip(request.remote_ip)
    Throttling.for(:user_signup).check_user_id(current_user.id)

You can add more helpers like this:

    Throttling::Base.class_eval do
      def check_user_id_and_document_id(user_id, doc_id)
        check("user_id:doc_id", "#{user_id}:#{doc_id}")
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Who are the authors?

This plugin has been created in Scribd.com for our internal use and then the sources were opened for other people to use. Most of the code in this package has been developed by Oleksiy Kovyrin and Dmytro Shteflyuk for Scribd.com and is released under the MIT license. For more details, see the LICENSE file.
