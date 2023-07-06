# Changelog

## 0.4.0 (July 6, 2023)

- Bump minimum Ruby requirement to 2.7.0
- Updated codebase to match StandardRB style guide

## 0.3.1 (April 13, 2012)

Features:

- When limit is omitted, no limits will be enforced (`check` always returns true)

Bugfixes:

- Fixed bug when action was allowed `limit + 1` times
- When limit is 0, `check` should always return `false`

## 0.3.0 (April 13, 2012)

Features:

- Added ability to retrieve custom value based on number of actions performed in a period of time

## 0.2.0 (April 12, 2012)

Bugfixes:

- Fixed bug when occurrences where increased for larger periods, when smaller ones did not pass

## 0.1.0 (April 12, 2012)

Features:

- Allows to throttle actions occurred in period of time
- Allows to specify limits inline or in external configuration file
- 100% test coverage
