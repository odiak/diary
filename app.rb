require "sinatra"
require "sequel"
require "redcarpet"
require "bcrypt"

require "logger"

unless defined?(RACK_ENV)
  RACK_ENV = ENV["RACK_ENV"] || "development"
end

Sequel.extension :core_extensions
Sequel::Model.plugin :timestamps, update_on_create: true

Sequel.database_timezone = :utc
Sequel.application_timezone = :local

DB = Sequel.connect("sqlite://db/#{RACK_ENV}.sqlite3")
DB.loggers << Logger.new($stdout)

class Post < Sequel::Model
end

class DiaryApp < Sinatra::Base

  configure do
    set :app_file, __FILE__
    disable :show_exceptions
    disable :session
    enable :logging

    pw = ENV["ENCRYPTED_PASSWORD"]
    set :encrypted_password, pw
  end

  helpers do
    def markdown(text)
      Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(text || "")
    end

    def require_password!
      begin
        pw = BCrypt::Password.new(settings.encrypted_password)
        if pw != params["password"]
          status 401
          halt "Unauthorized"
        end
      rescue StandardError
        status 401
        halt "Unauthorized"
      end
    end
  end

  get "/" do
    @posts = Post.order(:created_at.desc).all
    slim :index
  end

  get %r{\A/(\d+)\z} do |id|
    @post = Post.with_pk(id.to_i)

    pass unless @post

    @title = @post.title

    slim :single
  end

  get %r{\A/(\d+)/edit\z} do |id|
    @post = Post.with_pk(id.to_i) or pass

    slim :edit_post
  end

  post %r{\A/(\d+)/edit\z} do |id|
    require_password!

    @post = Post.with_pk(id.to_i) or pass

    @post.title = params["title"]
    @post.body = params["body"]
    @post.save

    redirect to("/#{@post.id}")
  end

  get "/new" do
    @post = Post.new

    slim :edit_post
  end

  post "/new" do
    require_password!

    @post = Post.new(
      title: params["title"],
      body: params["body"],
    )
    @post.save

    redirect to("/#{@post.id}")
  end

  get %r{\A/(\d+)/delete\z} do |id|
    @post = Post.with_pk(id.to_i) or pass

    slim :delete_post
  end

  post %r{\A/(\d+)/delete\z} do |id|
    require_password!

    @post = Post.with_pk(id.to_i) or pass

    @post.destroy

    redirect to("/")
  end

  not_found do
    "Not Found"
  end
end
