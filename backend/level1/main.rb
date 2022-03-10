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
    (days * car['price_per_day']) + (rental['distance'] * car['price_per_km'])
end

def generate_output(datas)
    File.write('data/output.json', JSON.pretty_generate({rentals: datas}))
end

generate_rentals