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
    "hello"
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
end
