require 'open-uri'

class MealController < ApplicationController
    include NeisHelper

    def index
        render json: {status: true}
    end

    def show
        schoolCode = params[:schoolCode]
        schoolStage = params[:schoolStage]
        year = params[:year]
        month = params[:month]
        begin
            render json: {status: true, schoolCode: schoolCode, schoolStage: schoolStage.to_i, year: year.to_i, month: month.to_i, menu: fetch(schoolCode, schoolStage, year, month)}
        rescue => e
            render json: {status: false, message: e.to_s}    
        end
    end

    private
    
    def fetch(schoolCode, schoolStage, year, month)
        # params validation
        raise "Invalid school code specified." unless schoolCode.match(/[A-Z]\d{9}/)
        raise "Invalid school stage specified." unless schoolStage.match(/^[2-4]$/)
        raise "Invalid year specified." unless year.match(/^\d{4}$/)
        raise "Invalid month specified." unless month.match(/^(0[1-9]|1[012])$/)
        schoolRegion = get_identifier(schoolCode)
        document = Nokogiri::HTML(open("https://stu.#{schoolRegion}.go.kr/sts_sci_md00_001.do?schulCode=#{schoolCode}&schulCrseScCode=#{schoolStage}&ay=#{year}&mm=#{month}"))
        parsed = document.css('.tbl_calendar tbody tr td div')
        data = []
        parsed.each do |p|
            diff = p.to_s.gsub(/&amp;/, '&').split('<br>', 2)
            date = Nokogiri::HTML(diff[0]).text.strip
            menu = diff[1].to_s.gsub("</div>", "").split(/\[조식\]|\[중식\]|\[석식\]/)
            breakfast = menu[0].to_s.gsub(/\d|[.]|[*]/, '').strip.split("<br>").reject!(&:empty?)
            lunch = menu[1].to_s.gsub(/\d|[.]|[*]/, '').strip.split("<br>").reject!(&:empty?)
            dinner = menu[2].to_s.gsub(/\d|[.]|[*]/, '').strip.split("<br>").reject!(&:empty?)
            unless (date.empty?)
                data << {
                    date: date.to_i,
                    breakfast: breakfast.nil? ? [] : breakfast,
                    lunch: lunch.nil? ? [] : lunch,
                    dinner: dinner.nil? ? [] : dinner
                }
            end
        end
        return data
    end
end
