require 'mina/bundler'
require 'mina/rails'

namespace :puma do
  set :web_server, :puma

  set :puma_role,      -> { user }
  set :puma_env,       -> { fetch(:rails_env, 'production') }
  set :puma_config,    -> { "#{fetch(:shared_path)}/config/puma.rb" }
  set :puma_socket,    -> { "#{fetch(:shared_path)}/tmp/sockets/puma.sock" }
  set :puma_state,     -> { "#{fetch(:shared_path)}/tmp/sockets/puma.state" }
  set :puma_pid,       -> { "#{fetch(:shared_path)}/tmp/pids/puma.pid" }
  set :puma_cmd,       -> { "#{fetch(:bundle_prefix)} puma" }
  set :pumactl_cmd,    -> { "#{fetch(:bundle_prefix)} pumactl" }
  set :pumactl_socket, -> { "#{fetch(:shared_path)}/tmp/sockets/pumactl.sock" }


  desc 'Start puma'
  task :start => :environment do
    command %[
      if [ -e '#{fetch(:pumactl_socket)}' ]; then
        echo 'Puma is already running!';
      else
        if [ -e '#{fetch(:puma_config)}' ]; then
          cd #{fetch(:current_path)} && #{fetch(:puma_cmd)} -q -d -e #{fetch(:puma_env)} -C #{fetch(:puma_config)}
        else
          cd #{fetch(:current_path)} && #{fetch(:puma_cmd)} -q -d -e #{fetch(:puma_env)} -b 'unix://#{fetch(:puma_socket)}' -S #{fetch(:puma_state)} --pidfile #{fetch(:puma_pid)} --control 'unix://#{fetch(:pumactl_socket)}'
        fi
      fi
    ]
  end

  desc 'Stop puma'
  task stop: :environment do
    command %[
      if [ -e '#{fetch(:pumactl_socket)}' ]; then
        cd #{fetch(:current_path)} && #{fetch(:pumactl_cmd)} -S #{fetch(:puma_state)} stop
        rm -f '#{fetch(:pumactl_socket)}'
      else
        echo 'Puma is not running!';
      fi
    ]
  end

  desc 'Restart puma'
  task restart: :environment do
    invoke :'puma:stop'
    invoke :'puma:start'
  end

  desc 'Restart puma (phased restart)'
  task phased_restart: :environment do
    command %[
      if [ -e '#{fetch(:pumactl_socket)}' ]; then
        cd #{fetch(:current_path)} && #{fetch(:pumactl_cmd)} -S #{fetch(:puma_state)} --pidfile #{fetch(:puma_pid)} phased-restart
      else
        echo 'Puma is not running!';
      fi
    ]
  end
end
