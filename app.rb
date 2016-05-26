require "sinatra"
require "sequel"

require "logger"

unless defined?(RACK_ENV)
  RACK_ENV = ENV["RACK_ENV"] || "development"
end

Sequel.extension :core_extensions
Sequel::Model.plugin :timestamps, update_on_create: true

DB = Sequel.connect("sqlite://db/#{RACK_ENV}.sqlite3")
DB.loggers << Logger.new($stdout)

class Post < Sequel::Model
end

class DiaryApp < Sinatra::Base
  get "/" do
    @posts = Post.order(:created_at.desc).all
    slim :index
  end

  get %r{\A/(\d+)} do |id|
    @post = Post.with_pk(id.to_i)

    pass unless @post

    slim :single
  end

  get "/edit" do
    @post = Post.new
    slim :edit_post
  end

  post "/edit" do
    @post = Post.new(
      title: params["title"] || "",
      body: params["body"] || "",
    )

    redirect to("/")
  end

  not_found do
    "Not Found"
  end
end
