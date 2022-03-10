require 'json'
require 'date' 

COMISSION_RATE = 0.3

def generate_rentals
    final_datas = []

    # extract json datas from file
    datas = get_input
    cars = prepare_datas(datas['cars'])

    datas['rentals'].each do |rental|
        car = cars[rental['car_id']]
        car_options = get_rental_options(datas['options'], rental['id'])

        # get number of days between two dates
        days = count_days(rental['start_date'], rental['end_date'])

        add_insurance_amount = calculate_insurance_amount(car_options, days)
        price = calculate_price(days, car, rental).to_i
        comission = generate_comission(days, price, add_insurance_amount)

        final_datas << { 
            id: rental['id'],
            options: car_options, 
            actions: define_action(price, comission, car_options, days, add_insurance_amount)
        }
    end

    # generate output json
    generate_output(final_datas)
end

def get_input
    JSON.parse(File.open('data/input.json').read)
end

def prepare_datas(datas)
    # generate new hash with id for index
    datas.map{ |data| [data['id'], data]}.to_h
end

def get_rental_options(datas, rental_id)
    options = datas.select{ |data| data['rental_id'].eql? rental_id }
    options.map{ |option| option['type']}
end

def count_days(begin_date, end_date)
    (Date.parse(end_date) - Date.parse(begin_date)).to_i + 1
end

def calculate_insurance_amount(car_options, days)
    (car_options.include? 'additional_insurance') ? 1000 * days : 0
end

def calculate_price(days, car, rental)
    distance_price = rental['distance'] * car['price_per_km']
    calculate_days_price(days, car['price_per_day']) + distance_price
end

def calculate_days_price(days, price_per_day)
    # substracted 1 day for first day in 100% 
    case days -= 1
    when 0
        decreasing_prices = 0 
    when 1...3
        decreasing_prices = ((price_per_day * 0.9) * days)
    when 4...9
        decreasing_prices = ((price_per_day * 0.9) * 3) + ((price_per_day * 0.7) * (days - 3))
    else
        decreasing_prices = ((price_per_day * 0.9) * 3) + ((price_per_day * 0.7) * 6) + ((price_per_day * 0.5) * (days - 9))
    end

    decreasing_prices += price_per_day
end

def generate_comission(days, price, add_insurance_amount)
    # get comission amount
    price = (price * COMISSION_RATE).to_i

    insurance_fee = price / 2
    assistance_fee = days * 100
    drivy_fee = (price + add_insurance_amount) - (insurance_fee + assistance_fee)

    { 
        "insurance_fee": insurance_fee.to_i,
        "assistance_fee": assistance_fee.to_i,
        "drivy_fee": drivy_fee.to_i
    }
end

def define_action(price, comission, car_options, days, add_insurance_amount)
    result = []
    actions = %w(driver owner insurance assistance drivy)

    # add options amount
    price += (500 * days) if car_options.include? 'gps'
    price += (200 * days) if car_options.include? 'baby_seat'
    price += add_insurance_amount

    actions.each do |action|
        case action
        when 'driver'
            amount = price
        when 'owner'
            amount = price - comission.values.sum
        else
            amount = comission["#{action}_fee".to_sym]
        end

        result << {
            "who": action,
            "type": (action.eql? 'driver') ? "debit" : "credit",
            "amount": amount.to_i
        }
    end

    result
end 

def generate_output(datas)
    File.write('data/output.json', JSON.pretty_generate({rentals: datas}))
end

generate_rentals