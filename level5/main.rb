require './json_file_manipulation.rb'
require 'date'

class GetAround
  include JsonFileManipulation

  ONE_EURO = 100
  PEOPLE = %w[driver owner insurance assistance drivy].freeze

  DISCOUNTS = {
    1 => 0.1,
    4 => 0.3,
    10 => 0.5
  }.freeze

  OPTION_DAILY_PRICES = {
    'gps' => 5 * ONE_EURO,
    'baby_seat' => 2 * ONE_EURO,
    'additional_insurance' => 10 * ONE_EURO
  }.freeze

  OPTIONS_INCOME_FOR = {
    'gps' => 'owner',
    'baby_seat' => 'owner',
    'additional_insurance' => 'drivy'
  }.freeze

  def initialize(input_file = './data/input.json')
    input = get_json_from_file(input_file)
    @cars = input['cars'].map { |car| [car['id'], car] }.to_h
    @rentals = input['rentals']
    @options = input['options'].group_by { |option| option['rental_id'] }
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

    insurance_fee = commission / 2.0
    assistance_fee = rental_duration * ONE_EURO
    drivy_fee = commission - insurance_fee - assistance_fee

    [insurance_fee, assistance_fee, drivy_fee]
  end

  def generate_action(who, amount)
    {
      who: who,
      type: who == 'driver' ? 'debit' : 'credit',
      amount: amount.to_i
    }
  end

  def generate_options_who_amounts(rental, rental_duration)
    additional_income = Hash.new(0)
    @options[rental['id']]&.each do |option|
      option_type = option['type']
      additional_income[OPTIONS_INCOME_FOR[option_type]] +=
        OPTION_DAILY_PRICES[option_type] * rental_duration
    end
    additional_income
  end

  def generate_actions(rental)
    rental_duration = rental_duration(rental)

    rental_price = calculate_rental_price(rental, rental_duration)
    commission = calculate_commission(rental_duration, rental_price)
    owner_income = rental_price - commission.sum

    additional_incomes = generate_options_who_amounts(rental, rental_duration)
    amounts = ([
      rental_price + additional_incomes.values.sum,
      owner_income
    ] << commission).flatten

    PEOPLE.count.times.map { |i| generate_action(PEOPLE[i], amounts[i] + additional_incomes[PEOPLE[i]]) }
  end

  def generate_rental(rental)
    options = @options[rental['id']]&.map { |option| option['type'] } || []
    {
      id: rental['id'],
      options: options,
      actions: generate_actions(rental)
    }
  end

  def rentals(output_file = './data/output.json')
    output_data = @rentals.map { |rental| generate_rental(rental) }
    write_json_to_file(output_data, output_file)
  end
end

GetAround.new.rentals
