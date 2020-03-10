# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :shops do
  primary_key :id
  String :name
  String :address
  String :city
  String :state
  String :country
  String :url, text: true
  Boolean :coffee
  Boolean :tea
  Boolean :smoothies
  String :seating
  String :google_stars
  String :yelp_stars
end
DB.create_table! :attend do
  primary_key :id
  foreign_key :shop_id
  foreign_key :user_id
  Boolean :attend
  Integer :rating
  String :comments, text: true
end
DB.create_table! :users do
   primary_key :id
   String :name
   String :email
   String :password
 end

# Insert initial (seed) data
shops_table = DB.from(:shops)

shops_table.insert(name: "Collectivo", 
                    address: "716 Church Street",
                    city: "Evanston",
                    state: "IL",
                    country: "USA",
                    url: "https://colectivocoffee.com/", 
                    coffee: true, 
                    tea: true,
                    smoothies: true,
                    seating: "large",
                    google_stars: "4.5",
                    yelp_stars: "4")

shops_table.insert(name: "Backlot", 
                    address: "1549 W Sherman Avenue",
                    city: "Evanston",
                    state: "IL",
                    country: "USA",
                    url: "http://backlotcoffee.com", 
                    coffee: true, 
                    tea: true,
                    smoothies: false,
                    seating: "small",
                    google_stars: "4.6",
                    yelp_stars: "5")

puts "database created"