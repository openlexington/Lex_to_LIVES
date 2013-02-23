require 'csv'

scores = CSV.read("restaurant_scores.csv") #TODO: Change this to take in passed filename

businesses = [["business_id", "name", "address", "city", "state"]]
violations = [["business_id", "date", "code"]]
inspections = [["business_id", "score", "date"]]

def convert_date_format(date)
  new_date = date[7..10]
  month_string = date[3..5]
  case month_string
  when "Jan"
    month = "01"
  when "Feb"
    month = "02"
  when "Mar"
    month = "03"
  when "Apr"
    month = "04"
  when "May"
    month = "05"
  when "Jun"
    month = "06"
  when "Jul"
    month = "07"
  when "Aug"
    month = "08"
  when "Sep"
    month = "09"
  when "Oct"
    month = "10"
  when "Nov"
    month = "11"
  when "Dec"
    month = "12"
  else
    month = "00"
  end

  day = date[0..1]

  new_date += month + day
end


def violation_desc(violation_id)
  # BROKEN
 case
 when "1"
   desc = "Source, Records, Condition, Spoilage, Adulterated"
 when "2"
   desc = "Container, properly labeled"
 when "3"
   desc = "Potentially hazardous food - safe temp"
 when "4"
   desc = ""
 when "5"
   desc = ""
 when "6"
   desc = ""
 when "7"
   desc = ""
 when "8"
   desc = ""
 when "9"
   desc = ""
 when "10"
   desc = ""
 when "11"
   desc = ""
 when "12"
   desc = ""
 when "13"
   desc = ""
 when "14"
   desc = ""
 when "15"
   desc = ""
 when "16"
   desc = ""
 when "17"
   desc = ""
 when "18"
   desc = ""
 when "19"
   desc = ""
 when "20"
   desc = ""
 when "21"
   desc = ""
 when "22"
   desc = ""
 when "23"
   desc = ""
 when "24"
   desc = ""
 when "25"
   desc = ""
 when "26"
   desc = ""
 when "27"
   desc = ""
 when "28"
   desc = ""
 when "29"
   desc = ""
 when "30"
   desc = ""
 when "31"
   desc = ""
 when "32"
   desc = ""
 when "33"
   desc = ""
 when "34"
   desc = ""
 when "35"
   desc = ""
 when "36"
   desc = ""
 when "37"
   desc = ""
 when "38"
   desc = ""
 else
   desc = ""
 end
end

scores.shift

scores.each do |entry|
  # Businesses
  business_entry = []
  business_entry.push(entry[0])
  business_entry.push(entry[1])
  business_entry.push(entry[2])
  business_entry.push("Lexington")
  business_entry.push("KY")

  businesses.push(business_entry)

  # Inspections
  inspection_entry = []
  inspection_entry.push(entry[0])
  inspection_entry.push(entry[5])
  inspection_entry.push(convert_date_format(entry[3]))

  inspections.push(inspection_entry)

  # Violations
  violation_entry = []
  violation_entry.push(entry[0])
  violation_entry.push(convert_date_format(entry[3]))
  violation_entry.push(entry[8])
  #violation_entry.push(violation_desc(entry[8]))

  violations.push(violation_entry)
end

businesses.uniq!
inspections.uniq!
violations.uniq!

CSV.open("businesses.csv", "wb") do |csv|
  businesses.each do |row|
    csv << row
  end
end

CSV.open("inspections.csv", "wb") do |csv|
  inspections.each do |row|
    csv << row
  end
end

CSV.open("violations.csv", "wb") do |csv|
  violations.each do |row|
    csv << row
  end
end
