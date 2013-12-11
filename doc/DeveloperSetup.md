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

The above command should clone the Github repository into *pcc-main* directory.

### Install Gem Dependencies

```
gem install bundler
bundle install
```
In case of error, ensure required libraries (headers) are installed in your local system.

#### A brief overview of Bundler

Bundler maintains a consistent environment for ruby applications. It tracks an application's code and the rubygems it needs to run, so that an application will always have the exact gems (and versions) that it needs to run. 

Reference: http://bundler.io/

To summarize the usage of Bundler:

* Define required Gems in Gemfile
* Install and Lock (version) Gems using: bundle install
* The Gemfile.lock is created. This ensures a version lock of the installed Gems.
* This approach ensures that correct version of Gems are used across all developer and production deployments.

### Setup Database

The default database configuration file (config/database.yml) is set to use sqlite3 which should be suitable for development. If you want to use MySQL or PostgreSQL, edit config/database.yml to set appropriate database driver after adding the gem dependency in Gemfile.

Setup database tables:

```
bundle exec rake db:migrate
```

It is a good practice to run database migration after every pull from the repository in order to sync local schema with other developers.

### Run Application Server

Start application server in default port (3000).
```
rails s
```

Start application server in custom port
```
rails s -p 8899
```

Reference
---------

* Ruby Installation with RVM: http://rvm.io/rubies/installing
* Gem Bundler: http://bundler.io/
* Ruby on Rails (3.x) Guide: http://guides.rubyonrails.org/v3.2.14/
* Ruby on Rails Introductory Tutorials:
  * http://guides.railsgirls.com/app/
  * http://rubyonrails.org/screencasts
* Suitable Editors
  * Sublime Text: http://www.sublimetext.com/
  * RedCar: http://redcareditor.com/
  * TextMate: http://macromates.com/
  * Aptana (Eclipse based): http://www.aptana.com/
  * NetBeans (need Rails plugin): https://netbeans.org/
