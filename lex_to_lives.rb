#!/usr/bin/env ruby

require 'csv'

# Usage:
#   transformer = LexToLIVES.new(file, businesses_file: 'bizniss.csv')
#   # outputs bizniss.csv, inspections.csv, violations.csv
#
#   transformer = LexToLIVES.new(file)
#   transformer.business_csv_file = 'bizniss.csv'
#   transformer.inspections_csv_file = 'insperksherns.csv'
#   transformer.transform
#   # outputs bizniss.csv, insperksherns.csv, violations.csv
#
class LexToLIVES
  attr_accessor :source_csv_file
  attr_accessor :businesses_csv_file
  attr_accessor :inspections_csv_file
  attr_accessor :violations_csv_file

  def self.transform(source_file = nil)
    if source_file.nil? || source_file.empty?
      raise ArgumentError, "No input file specified."
    end

    new(source_file).transform
  end

  def initialize(source_file, options = {})
    @source_csv_file = source_file
    @businesses_csv_file = options[:businesses_file] || 'businesses.csv'
    @inspections_csv_file = options[:inspections_file] || 'inspections.csv'
    @violations_csv_file = options[:violations_file] || 'violations.csv'
  end

  def transform(infile = @source_csv_file)
    businesses = [["business_id", "name", "address", "city", "state"]]
    violations = [["business_id", "date", "code", "description"]]
    inspections = [["business_id", "score", "date"]]

    CSV.foreach(infile, headers: true, header_converters: :symbol) do |entry|
      # reporting_area:605 premise_name:"#1 CHINA BUFFET" premise_address_1:"125 E. REYNOLDS ROAD, STE. 120" inspection_date:"12-Apr-2012" inspection_type:1 score:96 owner_name:"#1 CHINA BUFFET" critical_:nil violation:19 inspection_id:805726 violation:19 r_f_insp:nil inspection_id:805726 violation:19 weight:1 critical_yn:"NO"

      # Businesses
      business_entry = parse_business(entry)

      businesses.push(business_entry)

      # Inspections
      inspection_entry = parse_inspection(entry)

      inspections.push(inspection_entry)

      # Violations
      violation_entry = parse_violation(entry)

      violations.push(violation_entry)
    end

    businesses.uniq!
    inspections.uniq!
    violations.uniq!

    csv_write(businesses_csv_file, businesses)
    csv_write(inspections_csv_file, inspections)
    csv_write(violations_csv_file, violations)
  end #transform

  private

  def parse_business(row)
    [ row[:reporting_area],
      row[:premise_name],
      row[:premise_address_1],
      "Lexington",
      "KY" ]
  end

  def parse_inspection(row)
    [ row[:reporting_area],
      row[:score],
      convert_date_format(row[:inspection_date]) ]
  end

  def parse_violation(row)
    [ row[:reporting_area],
      convert_date_format(row[:inspection_date]),
      row[:violation],
      violation_desc(row[:violation]) ]
  end

  def convert_date_format(date)
    # 'off-by-one' puts January at index 1 so #index returns the right month number.
    months = %w(off-by-one Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

    day, month, year = date.split('-')
    month = months.index(month) || 0
    day = date[0..1]

    sprintf('%d%02d%02d', year.to_i, month.to_i, day.to_i)
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

  def csv_write(output_file, rows)
    CSV.open(output_file, "wb") do |csv|
      rows.each { |row| csv << row }
    end
  end
end


# Execute as shell script if invoked directly.
if caller.empty?
  LexToLIVES.transform ARGV[0]
end
