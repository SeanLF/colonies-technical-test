require './json_file_manipulation.rb'
require 'date'

class GetAround
  include JsonFileManipulation

  DISCOUNTS = {
    1 => 0.1,
    4 => 0.3,
    10 => 0.5
  }.freeze

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

  def calculate_rental_price_for_days(rental_duration, price_per_day)
    current_daily_price = price_per_day
    daily_costs = rental_duration.times.map do |days_past|
      current_daily_price = price_per_day * (1 - DISCOUNTS[days_past]) unless DISCOUNTS[days_past].nil?
      current_daily_price
    end
    daily_costs.sum
  end

  def calculate_rental_price(rental, rental_duration)
    car = @cars[rental['car_id']]

    price_per_day = car['price_per_day']
    price_per_km = car['price_per_km']

    [
      calculate_rental_price_for_days(rental_duration, price_per_day),
      price_per_km * rental['distance']
    ].sum
  end

  def calculate_commission(rental_duration, rental_price)
    commission = rental_price * 0.3

    insurance_fee = commission / 2
    assistance_fee = rental_duration * 100
    drivy_fee = commission - insurance_fee - assistance_fee

    [insurance_fee, assistance_fee, drivy_fee]
  end

  def generate_action(who, amount)
    {
      who: who,
      type: who == 'driver' ? 'debit' : 'credit',
      amount: amount
    }
  end

  def generate_actions(rental)
    people = %w[driver owner insurance assistance drivy]
    amounts = []

    rental_duration = rental_duration(rental)

    rental_price = calculate_rental_price(rental, rental_duration)
    commission = calculate_commission(rental_duration, rental_price)
    amounts = ([rental_price, rental_price - commission.sum] << commission).flatten

    people.count.times.map { |i| generate_action(people[i], amounts[i]) }
  end

  def generate_rental(rental)
    {
      id: rental['id'],
      actions: generate_actions(rental)
    }
  end

  def rentals(output_file = './data/output.json')
    output_data = @rentals.map { |rental| generate_rental(rental) }
    write_json_to_file(output_data, output_file)
  end
end

GetAround.new.rentals
