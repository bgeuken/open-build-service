# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
# require 'mina/rvm'    # for rvm support. (https://rvm.io)
require 'mina/rails'
require 'mina/git'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :application_name, 'obs'
set :domain, '149.44.172.53'
set :deploy_to, '/tmp'
set :repository, 'git://...'
set :branch, 'master'

# Optional settings:
set :user, 'root'          # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
# set :shared_dirs, fetch(:shared_dirs, []).push('public/assets')
# set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use', 'ruby-1.9.3-p125@default'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.3.0 --skip-existing}
end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    #invoke :'rails:db_migrate'
    #invoke :'deploy:cleanup'disable_feature_tests_for_s390

    # Check if there is anything to deploy
    command %{zypper up -D -y obs-api | grep -q '^Nothing to do.$'; echo $?}

    # Generate a diff
    command %{zypper up -d obs-api}
    command %{rpm2cpio /var/cache/zypp/packages/OBS\:Server\:Unstable/noarch/obs-api*.rpm | cpio -idmv ./srv/www/obs/api/last_deploy}
    command %{new_version=`cat ./srv/www/obs/api/last_deploy`}
    command %{old_version=`cat /srv/www/obs/api/last_deploy`}
    foo = command %{curl "https://github.com/openSUSE/open-build-service/compare/$old_version...$new_version.diff"}
    if foo['db/migrate']
      puts 'There are pending migrations'
      # interactive part goes here
    end

    #command %{zypper up obs-api obs-factory-engine}
    command %{touch /tmp/deployed}

   #on :launch do
   #  in_path(fetch(:current_path)) do
   #    command %{mkdir -p tmp/}
   #    command %{touch tmp/restart.txt}
   #  end
   #end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs
