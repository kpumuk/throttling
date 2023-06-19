# Throttling

[![Gem Version](https://badge.fury.io/rb/throttling.svg)](https://badge.fury.io/rb/throttling)
[![Gem Downloads](https://img.shields.io/gem/dt/throttling.svg)](https://badge.fury.io/rb/throttling)
[![Changelog](https://img.shields.io/badge/Changelog-latest-blue.svg)](https://github.com/kpumuk/throttling/blob/main/CHANGELOG.md)

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

    request_priority:
      period: 86400
      default_value: 25
      values:
        high_priority:
          limit: 5
          value: 10
        medium_priority:
          limit: 15
          value: 15
        low_priority:
          limit: 100
          value: 20

This example covers three different scenarios:

1. Single period. In this case only 20 actions will be allowed in a period of
   one hour (3600 seconds).

2. Multiple periods. Action will be allowed to perform 300 times in 10 minutes,
   1000 times an hour, and 10000 times a day.

3. This special case covers following scenario: based on the number of actions,
   it returns a value, or default value when largest limit is reached. In this
   case it will return 10, when there were 5 or less requests (including current one),
   15 for up to 15 requests, 20 for up to 100 requests, and 25 when there were
   more than 100 requests.

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

## Use cases

### Limiting number of sign-ups

    user_signup:
      limit: 20
      period: 3600

Limit the number of sign-ups to 20 per hour per IP address:

    Throttling.for('user_signup').check_ip(request.remote_ip)

### Limiting number of document uploads

    document_uploads:
      minutely:
        limit: 5
        period: 600
      hourly:
        limit: 10
        period: 3600
      daily:
        limit: 50
        period: 86400

In this case user will be allowed to upload 5 documents in 10 minutes, 10 documents
in an hour, or 50 documents a day:

    Throttling.for('document_uploads').check_user_id(current_user.id)

### Prioritizing uploads based on number of uploads

    document_priorities:
      period: 86400
      default_value: 25
      values:
        high_priority:
          limit: 5
          value: 10
        medium_priority:
          limit: 15
          value: 15
        low_priority:
          limit: 100
          value: 20

All documents could be prioritized based on the number of uploads: if user uploads
less than 5 documents a day, they all will have priority 10. Next 10 documents
(first five keep their original priority) will receive priority 15. Documents
16 to 100 will get priority 20, and everything else will get priority 25.

    Throttling.for('document_priorities').check_user_id(current_user.id)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Who are the authors?

This plugin has been created in Scribd.com for our internal use and then the sources were opened for other people to use. Most of the code in this package has been developed by Oleksiy Kovyrin and Dmytro Shteflyuk for Scribd.com and is released under the MIT license. For more details, see the LICENSE file.
