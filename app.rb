require "sinatra"
require "sequel"
require "redcarpet"

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

  helpers do
    def markdown(text)
      Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(text || "")
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
    @post = Post.new(
      title: params["title"],
      body: params["body"],
    )
    @post.save

    redirect to("/#{@post.id}")
  end

  not_found do
    "Not Found"
  end
end
