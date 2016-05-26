require "sinatra"

class DiaryApp < Sinatra::Base
  get "/" do
    "hello"
  end
end
