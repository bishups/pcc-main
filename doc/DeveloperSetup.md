Developer Setup
===============

Pre-requisites
--------------

* Ruby 1.9.x (should work on Ruby 2.x)
* Git

Basic Setup
-----------

### Clone Repository

```
git clone https://username@github.com/bishups/pcc-main
```

### Install Gem Dependencies

```
gem install bundler
bundle install
```

### Setup Database

The default database configuration file (config/database.yml) is set to use sqlite3 which should be suitable for development. If you want to use MySQL or PostgreSQL, edit config/database.yml to set appropriate database driver after adding the gem dependency in Gemfile.

Setup database tables:

```
bundle exec rake db:migrate
```

It is a good practice to run database migrate after every pull from the repository in order to sync local schema with other developers.

