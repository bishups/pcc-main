set :application, "pcc_main"
set :deploy_to, "/var/apps/#{application}"

default_run_options[:pty] = true
set :scm, :git
set :repository, 'https://github.com/bishups/pcc-main'

set :user, "abhisek"
set :use_sudo, false

role :app, "SERVER"
role :web, "SERVER"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after "deploy:update_code" do
  run "rm -rf #{release_path}/config/database.yml"
  run "ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml"

  #run "cd #{release_path} && bundle install"
  #run "cd #{release_path} && bundle exec rake db:migrate"
  #run "cd #{release_path} && RAILS_ENV=production bundle exec rake assets:precompile"
end

before :deploy do
  #system("bundle exec rake assets:precompile")
end

after :deploy do
  #system("bundle exec rake assets:clean")
end
