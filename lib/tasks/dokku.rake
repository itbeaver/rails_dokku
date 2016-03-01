namespace :dokku do
  @app_name_stage = '' # default
  @app_domain_stage = '' # default
  @app_name_production = ''
  @app_domain_production = ''

  if Rails.env.production?
    @app_name = @app_name_production
    @app_domain = @app_domain_production
  else
    @app_name = @app_name_stage
    @app_domain = @app_domain_stage
  end

  desc 'Dokku migrate'
  task :migrate do
    run_in_dokku "run #{@app_name} rake db:migrate"
  end

  desc 'Dokku logs'
  task :logs do
    run_in_dokku "logs #{@app_name}"
  end

  desc 'Install plugins'
  task :install_plugins do
    run_in_dokku_as_root 'dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres'
  end

  desc 'Create app and PG databse'
  task :setup do
    run_in_dokku "apps:create #{@app_name}"
    run_in_dokku "postgres:create #{@app_name}"
    run_in_dokku "postgres:link #{@app_name} #{@app_name}"
  end

  desc 'Deploy'
  task :deploy do
    if Rails.env.production?
      system 'git push production master'
    else
      system 'git push stage master'
    end
  end

  desc 'Add remote to git'
  task :git_add do
    if Rails.env.production?
      system "git remote add production dokku@#{@app_domain}:#{@app_name}"
    else
      system "git remote add stage dokku@#{@app_domain}:#{@app_name}"
    end
  end

  desc 'Databse from production to stage'
  task :pg_db_push_to_stage do
    name = @app_name_production + Time.now.strftime("%F-%H%M") + '.dump'
    system "ssh -t root@#{@app_domain_production} dokku postgres:export #{@app_name_production} > #{name}"
    system "ssh -t root@#{@app_domain_stage} dokku postgres:import #{@app_name_stage} < #{args[:arg1]}"
  end

  desc 'Get database to local'
  task :export_pg do
    name = @app_name + Time.now.strftime("%F-%H%M") + '.dump'
    run_in_dokku_as_root "dokku postgres:export #{@app_name} > #{name}"
  end

  desc 'Push database to server'
  task :import_pg, [:arg1] do |t, args|
    run_in_dokku_as_root "dokku postgres:import #{@app_name} < #{args[:arg1]}"
  end

  desc 'show config without params or add config: rake dokku:config[PARAM=PARAM]'
  task :config, [:arg1] do |t, args|
    if args[:arg1].blank?
      run_in_dokku "config #{@app_name}"
    else
      run_in_dokku "config:set #{@app_name} #{args[:arg1]}"
    end
  end

  desc 'add credentials to dokku'
  task :add_credentials do
    run_in_dokku_as_root 'cat /root/.ssh/authorized_keys | sshcommand acl-add dokku dokku'
  end

  def run_in_dokku_as_root(command = 'logs')
    system "ssh -t root@#{@app_domain} " + command
  end

  def run_in_dokku(command = 'logs')
    system "ssh -t dokku@#{@app_domain} " + command
  end
end
