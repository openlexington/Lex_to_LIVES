require 'csv'

scores = CSV.read("restaurant_scores.csv") #TODO: Change this to take in passed filename

businesses = [["business_id", "name", "address", "city", "state"]]
violations = [["business_id", "date", "code"]]
inspections = [["business_id", "score", "date"]]

def convert_date_format(date)
  new_date = date[7..10]
  month_string = date[3..5]
  # months = %(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
  # month = '%00d' % (months.index(month_string.to_i) || 0)
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
  # As a hash for easier maintenance
  descriptions = {
    1  => 'FOOD SOURCES: Source, Records, Condition, Spoilage, Adulterated',
    2  => 'FOOD SOURCES: Container, properly labeled',
    3  => 'FOOD PROTECTION: Potentially hazardous food - safe temp.',
    4  => 'FOOD PROTECTION: Facilities to maintain product temp.',
    5  => 'FOOD PROTECTION: Thermometers provided and conspicuous',
    6  => 'FOOD PROTECTION: Potentially hazardous food properly thawed',
    7  => 'FOOD PROTECTION: Pot. hazardous food not re-served',
    8  => 'FOOD PROTECTION: Food Protection - storage, prep, display, service, transp.',
    9  => 'FOOD PROTECTION: Handling of food (ice) minimized. Dispensing utensils properly stored during use.',
    10 => 'PERSONNEL: Personnel with infections restricted & proper reporting',
    11 => 'PERSONNEL: Hands washed and clean, hygienic practices preventing contamination from hands',
    12 => 'PERSONNEL: Clean clothes, hair restraints',
    13 => 'PERSONNEL: Supervision: Person in charge present and demonstrates knowledge of food safety principles',
    14 => 'FOOD EQUIPMENT & UTENSILS: Food (ice) contact surfaces designed, constructed, maintained, installed',
    15 => 'FOOD EQUIPMENT & UTENSILS: Food/Non-food contact surfaces designed, constructed, maintained, installed',
    16 => 'FOOD EQUIPMENT & UTENSILS: Dishwashing facilities designed, constructed, maintained, installed, located, operated. Accurate therm., chem. test kits, gauge',
    17 => 'FOOD EQUIPMENT & UTENSILS: Sanitization rinse, temp., conce., exp. time, equip. utensils, sanitized',
    18 => 'FOOD EQUIPMENT & UTENSILS: Wiping cloths clean, use restricted',
    19 => 'FOOD EQUIPMENT & UTENSILS: Food/Non-food contact surfaces of equip/utensils clean',
    20 => 'FOOD EQUIPMENT & UTENSILS: Storage, handling of clean equipment/utensils/single service articles',
    21 => 'WATER: Water source, safe, hot & cold',
    22 => 'SEWAGE: Sewage and waste disposal',
    23 => 'PLUMBING: Installed, maintained',
    24 => 'PLUMBING: Cross-connection, back siphonage, backflow',
    25 => 'TOILET & HANDWASHING FACILITIES: No., conv., designed, installed',
    26 => 'TOILET & HANDWASHING FACILITIES: Toilet rooms enclosed, self-closing doors, fixtures, good repair, clean, tissue, hand cleansers, sanitary towels/hand-drying devices provided, proper waste receptacles',
    27 => 'GARBAGE DISPOSAL: Containers or receptacles, covered, adequate number, insect/rodent proof, frequency, clean. Outside storage area enclosures properly constructed, clean, controlled incineration.',
    28 => 'INSECT, RODENT, ANIMAL CONTROL: No insects, rodents, birds, turtles, other animals',
    29 => 'OUTER OPENINGS: Outer openings protected',
    30 => 'FLOORS, WALLS, CEILINGS & VENTILATION: Floors constructed, drained, clean, good repair, covering installation, easily cleanable',
    31 => 'FLOORS, WALLS, CEILINGS & VENTILATION: Walls, ceiling, attached equipment constructed, good repair, clean surfaces, easily cleanable. Rooms and equipment vented as required.',
    32 => 'LIGHTING: Lighting provided as required, fixtures shielded',
    33 => 'OTHER OPERATIONS: Toxic Items properly stored, labeled, used',
    34 => 'OTHER OPERATIONS: Premises main, free of litter, misc. articles, cleaning/maint. equip. properly stored. Authorized personnel rooms clean, lockers provided, located, used.',
    35 => 'OTHER OPERATIONS: Separation from living/sleeping quarters. Laundry, clean or soiled linen properly stored.',
    36 => 'CONFORMANCE WITH APPROVED PROCEDURES: Compliance with variance, specialized process, and HACCP plan',
    37 => 'HIGHLY SUSCEPTIBLE POPULATIONS: Pasteurized foods used; prohibited foods not offered',
    38 => 'CONSUMER ADVISORY: Consumer advisory provided for raw or undercooked food'
  }

  descriptions[violation_id.to_i]
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
