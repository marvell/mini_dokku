#!/usr/bin/ruby

require 'erb'

class Bootstrap
  SITES_PATH = '/data/sites'
  SITE_DIRECTORIES = {
    :public => 'public',
    :logs => 'logs',
    :repository =>'.git'
  }
  TEMPLATES_PATH = '/data/scripts/templates'
  TEMPLATES = {
    :git_hook => 'post-receive.erb',
    :nginx_config => 'nginx.erb'
  }

  attr_accessor :host, :site_path, :public_path, :logs_path, :repository_path

  def initialize(params)
    @host = params[0]
    @site_path = File.expand_path(@host, SITES_PATH)
    @public_path = File.join(@site_path, SITE_DIRECTORIES[:public])
    @logs_path = File.join(@site_path, SITE_DIRECTORIES[:logs])
    @repository_path = File.join(@site_path, SITE_DIRECTORIES[:repository])

    unless File.exist?(@site_path)
      log('Creating directories...')
      Dir.mkdir(@site_path)
      SITE_DIRECTORIES.each do |key, directory|
        Dir.mkdir(File.join(@site_path, directory))
      end

      log('Initialize GIT repository...')
      `git init --bare #{@repository_path}`
      File.open(File.join(@repository_path, 'hooks', 'post-receive'), 'w', 0755) do |f|
        f.write(render(:git_hook))
      end

      log('Setting NGINX config file...')
      File.open(File.join(@site_path, 'nginx.conf'), 'w') do |f|
        f.write(render(:nginx_config))
      end

      log('Restarting NGINX server...')
      `sudo service nginx restart`

      log("URL: http://#{host}/")
    end
  end

  def render(template)
    template_path = File.join(TEMPLATES_PATH, TEMPLATES[template])
    ERB.new(File.read(template_path)).result(binding)
  end

  def log(message)
    $stderr.puts("---> #{message}")
  end

end

print Bootstrap.new(ARGV).repository_path
