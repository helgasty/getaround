require 'json'
require 'date' 

def generate_rentals
    final_datas = []

    # extract json datas from file
    datas = get_input
    cars = prepare_datas(datas['cars'])

    datas['rentals'].each do |rental|
        car = cars[rental['car_id']]

        # get number of days between two dates
        days = count_days(rental['start_date'], rental['end_date'])

        final_datas << { 
            id: rental['id'], 
            price: calculate_price(days, car, rental).to_i
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

def count_days(begin_date, end_date)
    (Date.parse(end_date) - Date.parse(begin_date)).to_i + 1
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

def generate_output(datas)
    File.write('data/output.json', JSON.pretty_generate({rentals: datas}))
end

generate_rentals