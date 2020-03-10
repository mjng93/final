# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"    
require "sinatra/cookies"                                                                    #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"      
require "geocoder"                                                                #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

shops_table = DB.from(:shops)
attend_table = DB.from(:attend)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    puts "params: #{params}"

    pp shops_table.all.to_a
    @shops = shops_table.all.to_a
    view "shops"
end

get "/shops/:id" do
    puts "params: #{params}"

    @shop = shops_table.where(id: params[:id]).to_a[0]
    pp @shop
    @users_table = users_table 
    @attend = attend_table.where(shop_id: @shop[:id]).to_a
    @going_count = attend_table.where(shop_id: @shop[:id], attend: true).count
    @review_avg = attend_table.where(shop_id: @shop[:id], attend: true).avg(:rating)
   

    view "shop"
end

get "/shops/:id/attend/new" do
    puts "params: #{params}"

    @shop = shops_table.where(id: params[:id]).to_a[0]
    view "new_attend"
end

get "/shops/:id/attend/create" do
    puts "params: #{params}"

    @users_table = users_table 
    @shop = shops_table.where(id: params[:id]).to_a[0]
    
    attend_table.insert(
    shop_id: @shop[:id],
    user_id: cookies["user_id"],
    rating: params["rating"],
    comments: params["comments"],
    attend: params["attend"]
    )

    view "create_attend"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts "params: #{params}"

    @users = users_table.where(id: params[:id]).to_a[0]
    
    users_table.insert(
    name: params["name"],
    email: params["email"],
    password: BCrypt::Password.create(params["password"])
    )

    view "create_user"
end

get "/logins/new" do

    view "new_login"
end

post "/logins/create" do
    puts "params: #{params}"

    @user = users_table.where(email: params["email"]).to_a[0]
    if @user && BCrypt::Password.new(@user[:password])==params["password"]

        #know user is logged in, but encrypt it so it's not a cookie
        #session and cookie arrays are automatically stored here through sinatra 
        session["user_id"] = @user[:id]
        

        view "create_login"
    else 
        view "create_login_failed"
    end
end

get "/logout" do

    @current_user = users_table.where(id: session["user_id"]).to_a[0]
    session["user_id"] = nil

    view "logout"
end

puts "success"