require 'httparty'
require 'cgi'
require 'titleize'

class TripPlanner
  attr_reader :user, :forecast, :recommendation
  
  def initialize
    @recommendation = []
  end
  
  def plan
    create_user
    retrieve_forecast
    create_recommendation
    display_recommendation
  end
  
  def display_recommendation 
    puts "Okay #{@user.name}, here is a list of items you might want to pack for your #{@user.duration} day trip to #{@user.destination}:"
    puts @recommendation
  end
  
  # def save_recommendation
  # end
  
  def create_user
    puts "Welcome to TripPlanner, please enter your name."
    user = gets.chomp.titleize
    puts "Please enter the city you're traveling to."
    city = gets.chomp.titleize
    duration = 0
    puts "Please enter the number of days you'll be in #{city}."
    while duration < 1
      duration = gets.chomp.to_i
      if duration < 1 
        puts "Please enter a valid integer greater than 0."
      end
    end
    @user = User.new(user, city, duration)
  end
  
  def retrieve_forecast
    call_api
    parse_result
  end
  
  def call_api
    @user_trip = HTTParty.get("http://api.openweathermap.org/data/2.5/forecast/daily?q=#{CGI.escape(@user.destination)}&units=imperial&cnt=#{@user.duration}")
  end
  
  

  def parse_result
    @forecast = []
    if @user_trip['list'].nil? 
      puts "Sorry, location not found, please try again."
      exit 0
    end
    @user_trip["list"].each do |day|
      @forecast << Weather.new(day["temp"]["min"], day['temp']['max'], day['weather'][0]['id'])
    end
  end
  
  def create_recommendation
    collect_clothes
    collect_accessories
  end
  
  def collect_clothes
    @forecast.each do |weather|
      @recommendation = @recommendation | weather.appropriate_clothing
    end
  end
  
  def collect_accessories
    @forecast.each do |weather|
      @recommendation = @recommendation | weather.appropriate_accessories
    end
  end


end

class Weather
  attr_reader :min_temp, :max_temp, :condition
  

  CLOTHES = [
    {
      min_temp: -50, max_temp: 0,
      recommendation: [
        "insulated parka", "long underwear", "fleece-lined jeans",
        "mittens", "knit hat", "chunky scarf"
      ]
    },
    {
      min_temp: 0.01, max_temp: 32,
      recommendation: [
        "insulated parka", "fleece-lined jeans",
        "mittens", "knit hat", "scarf"
      ]
    },
    {
      min_temp: 32.01, max_temp: 50,
      recommendation: [
        "coat", "jeans", "scarf"
      ]
    },
    {
      min_temp: 50.01, max_temp: 75,
      recommendation: [
        "sweater", "light jacket", "jeans"
      ]
    },
    {
      min_temp: 75.01, max_temp: 120,
      recommendation: [
        "shorts", "t-shirt"
      ]
    }
  ]

  ACCESSORIES = [
    {
      condition: [200, 531],
      recommendation: [
        "galoshes", "umbrella"
      ]
    },
    {
      condition: [600, 622],
      recommendation: [
        "umbrella", "snow boots"
      ]
    },
    {
      condition: [800, 804],
      recommendation: [
        "sun screen", "sun glasses"
      ]
    },
    {
      condition: [956, 960],
      recommendation: [
        "windbreaker"
      ]
    },
    {
      condition: [961, 962],
      recommendation: [
        "bible", "quran", "torah"
      ]
    }
  ]
  
  def initialize(min_temp, max_temp, condition)
    @min_temp = min_temp
    @max_temp = max_temp
    @condition = condition
  end
  
  def self.clothing_for(temp)
    CLOTHES.each do |clothes|
      if temp.between?(clothes[:min_temp], clothes[:max_temp])
        return clothes[:recommendation]
        break
      end
    end
  end
      

  
  def self.accessories_for(condition)
    ACCESSORIES.each do |acc|
      if condition.between?(acc[:condition][0], acc[:condition][1])
        return acc[:recommendation]
        break
      end
    end
  end

  def appropriate_clothing
    Weather.clothing_for(self.min_temp) | Weather.clothing_for(self.max_temp)
  end
      
  
  def appropriate_accessories
    Weather.accessories_for(self.condition) 
  end



end

class User
  attr_reader :name, :destination, :duration
  
  def initialize(name, destination, duration)
    @name = name
    @destination = destination
    @duration = duration
  end

end


trip_planner = TripPlanner.new
trip_planner.plan


