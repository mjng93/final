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
   

    results = Geocoder.search("#{@shop[:address]},#{@shop[:city]} #{@shop[:state]}")
    lat_long_results = results.first.coordinates
    @lat_long = "#{lat_long_results[0]}, #{lat_long_results[1]}" # => [lat, long]
    puts @lat_long
    puts "lat long above"
    #@lat_long = "#{@lat},#{@long}"
    #"#{lat_long[0]} #{lat_long[1]}"

    view "shop"
end

get "/shops/:id/attend/new" do
    puts "params: #{params}"

    @shop = shops_table.where(id: params[:id]).to_a[0]
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
    
    if @current_user
    view "new_attend"
    else 
    view "please_login"
    end
end

get "/shops/:id/attend/create" do
    puts "params: #{params}"

    @users_table = users_table 
    @shop = shops_table.where(id: params[:id]).to_a[0]
    
    attend_table.insert(
    shop_id: @shop[:id],
    user_id: session["user_id"],
    rating: params["rating"],
    comments: params["comments"],
    attend: params["attend"]
    )

    view "create_attend"
end

get "/attend/:id/edit" do
    puts "params: #{params}"

    @attend = attend_table.where(id: params["id"]).to_a[0]
    @shop = shops_table.where(id: @attend[:shop_id]).to_a[0]
    
    view "edit_attend"
end

post "/attend/:id/update" do
    puts "params: #{params}"
  
    @attend = attend_table.where(id: params["id"]).to_a[0] #remember, this route is stateless, so we only know the id of the rsvp
    @shop = shops_table.where(id: @attend[:shop_id]).to_a[0]
    if @current_user && @current_user[:id]==@attend[:user_id]
    attend_table.where(id: params["id"]).update(
        rating: params["rating"],
        comments: params["comments"],
        attend: params["attend"])
    end

    view "update_attend"
end

get "/attend/:id/destroy" do
    puts "params: #{params}"

    
    @attend = attend_table.where(id: params["id"]).to_a[0]
    @shop = shops_table.where(id: @attend[:shop_id]).to_a[0]
    attend_table.where(id: params["id"]).delete

    view "destroy_attend"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts "params: #{params}"

existing_user = users_table.where(email: params["email"]).to_a[0]
if existing_user
    view "error"
else
    @users = users_table.where(id: params[:id]).to_a[0]
    
    users_table.insert(
    name: params["name"],
    email: params["email"],
    password: BCrypt::Password.create(params["password"])
    )

    view "create_user"
end
end

get "/logins/new" do

    view "new_login"
end

post "/logins/create" do
    puts "params: #{params}"

    @user = users_table.where(email: params["email"]).to_a[0]
    if @user && BCrypt::Password.new(@user[:password])==params["password"]

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