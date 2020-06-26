require './json_file_manipulation.rb'
require 'date'

class GetAround
  include JsonFileManipulation

  def initialize(input_file = './data/input.json')
    input = get_json_from_file(input_file)
    @cars = cars_hash(input['cars'])
    @rentals = input['rentals']
  end

  def cars_hash(cars_array)
    cars_array.map { |hash| [hash['id'], hash] }.to_h
  end

  def rental_duration(rental)
    (Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1
  end

  def calculate_rental_price(rental)
    car = @cars[rental['car_id']]

    price_per_day = car['price_per_day']
    price_per_km = car['price_per_km']

    [
      price_per_day * rental_duration(rental),
      price_per_km * rental['distance']
    ].sum
  end

  def generate_rental(rental)
    {
      id: rental['id'],
      price: calculate_rental_price(rental)
    }
  end

  def rentals(output_file = './data/output.json')
    output_data = @rentals.map { |rental| generate_rental(rental) }
    write_json_to_file(output_data, output_file)
  end
end

GetAround.new.rentals
