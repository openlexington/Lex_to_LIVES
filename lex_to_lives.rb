#!/usr/bin/env ruby

require 'csv'

# Usage:
#   transformer = LexToLIVES.new(file, businesses_file: 'bizniss.csv')
#   transformer.transform
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

  attr_accessor :businesses
  attr_accessor :violations
  attr_accessor :inspections

  class Business < Struct.new(:business_id, :name, :address, :city, :state); end
  class Violation < Struct.new(:business_id, :date, :code, :description); end
  class Inspection < Struct.new(:business_id, :score, :date); end

  def initialize(source_file = nil, options = {})
    @source_csv_file = source_file
    @businesses_csv_file = options[:businesses_file] || 'businesses.csv'
    @inspections_csv_file = options[:inspections_file] || 'inspections.csv'
    @violations_csv_file = options[:violations_file] || 'violations.csv'
  end

  # Read Lexington-format CSV file, parse, emit LIVES-format CSV output files.
  def transform(infile = nil)
    infile ||= source_csv_file

    csv_parse(infile)

    csv_write(businesses_csv_file, Business.members, businesses)
    csv_write(inspections_csv_file, Inspection.members, inspections)
    csv_write(violations_csv_file, Violation.members, violations)
  end

  def exclude?(business)
    # Yelp can't aggregate the various facility inspections into the master keeneland inspection
    business.name.match(/^keeneland/i)
  end

  # Read Lexington-format CSV file, parse into internal data structs.
  def csv_parse(infile)
    self.businesses  = []
    self.inspections = []
    self.violations  = []

    CSV.foreach(infile, headers: true, header_converters: :symbol) do |entry|

      business = parse_business(entry)
      unless exclude?(business)
        businesses  << business
        inspections << parse_inspection(entry)
        self.violations += parse_violation_list(entry)
      end
    end

    businesses.uniq!
    inspections.uniq!
    violations.uniq!
  end

  # Write LIVES-format CSV file from internal data structs.
  def csv_write(output_file, row_headers, row_structs)
    csv_opts = {headers: row_headers, write_headers: true}

    CSV.open(output_file, "wb", csv_opts) do |csv|
      row_structs.each { |row| csv << row.to_a }
    end
  end

  private

  def parse_business(row)
    Business.new.tap do |b|
      b.business_id = row[:est_number].to_i
      b.name        = row[:premise_name]
      b.address     = row[:premise_address]
      b.city        = "Lexington"
      b.state       = "KY"
    end
  end

  def parse_inspection(row)
    Inspection.new.tap do |i|
      i.business_id = row[:est_number].to_i
      i.score       = row[:score]
      i.date        = convert_date_format(row[:inspection_date])
    end
  end

  def parse_violation_list(row)
    return [] if row[:violation_list].nil?

    row[:violation_list].split(' ').map do |violation|
      Violation.new.tap do |v|
        v.business_id = row[:est_number].to_i
        v.date = convert_date_format(row[:inspection_date])
        v.code = violation
        violation_desc = violation_desc(violation)
        v.description = "Standard not met. #{violation_desc}" if (violation_desc)
      end
    end
  end

  def convert_date_format(date)
    DateTime.strptime(date, '%m/%d/%y').strftime('%Y%m%d')
  end

  def violation_desc(violation_id)
    # As a hash for easier maintenance
    descriptions = {
      1 => 'Food Sources: Source, Records, Condition, Spoilage, Adulterated',
      2 => 'Food Sources: Container, properly labeled',
      3 => 'Food Protection: Potentially hazardous food - safe temp.',
      4 => 'Food Protection: Facilities to maintain product temp.',
      5 => 'Food Protection: Thermometers provided and conspicuous',
      6 => 'Food Protection: Potentially hazardous food properly thawed',
      7 => 'Food Protection: Pot. hazardous food not re-served',
      8 => 'Food Protection: Food Protection - storage, prep, display, service, transp.',
      9 => 'Food Protection: Handling of food (ice) minimized. Dispensing utensils properly stored during use.',
      10 => 'Personnel: Personnel with infections restricted & proper reporting',
      11 => 'Personnel: Hands washed and clean, hygienic practices preventing contamination from hands',
      12 => 'Personnel: Clean clothes, hair restraints',
      13 => 'Personnel: Supervision: Person in charge present and demonstrates knowledge of food safety principles',
      14 => 'Food Equipment & Utensils: Food (ice) contact surfaces designed, constructed, maintained, installed',
      15 => 'Food Equipment & Utensils: Food/Non-food contact surfaces designed, constructed, maintained, installed',
      16 => 'Food Equipment & Utensils: Dishwashing facilities designed, constructed, maintained, installed, located, operated. Accurate therm., chem. test kits, gauge',
      17 => 'Food Equipment & Utensils: Sanitization rinse, temp., conce., exp. time, equip. utensils, sanitized',
      18 => 'Food Equipment & Utensils: Wiping cloths clean, use restricted',
      19 => 'Food Equipment & Utensils: Food/Non-food contact surfaces of equip/utensils clean',
      20 => 'Food Equipment & Utensils: Storage, handling of clean equipment/utensils/single service articles',
      21 => 'Water: Water source, safe, hot & cold',
      22 => 'Sewage: Sewage and waste disposal',
      23 => 'Plumbing: Installed, maintained',
      24 => 'Plumbing: Cross-connection, back siphonage, backflow',
      25 => 'Toilet & Handwashing Facilities: No., conv., designed, installed',
      26 => 'Toilet & Handwashing Facilities: Toilet rooms enclosed, self-closing doors, fixtures, good repair, clean, tissue, hand cleansers, sanitary towels/hand-drying devices provided, proper waste receptacles',
      27 => 'Garbage Disposal: Containers or receptacles, covered, adequate number, insect/rodent proof, frequency, clean. Outside storage area enclosures properly constructed, clean, controlled incineration.',
      28 => 'Insect, Rodent, Animal Control: No insects, rodents, birds, turtles, other animals',
      29 => 'Outer Openings: Outer openings protected',
      30 => 'Floors, Walls, Ceilings & Ventilation: Floors constructed, drained, clean, good repair, covering installation, easily cleanable',
      31 => 'Floors, Walls, Ceilings & Ventilation: Walls, ceiling, attached equipment constructed, good repair, clean surfaces, easily cleanable. Rooms and equipment vented as required.',
      32 => 'Lighting: Lighting provided as required, fixtures shielded',
      33 => 'Other Operations: Toxic Items properly stored, labeled, used',
      34 => 'Other Operations: Premises main, free of litter, misc. articles, cleaning/maint. equip. properly stored. Authorized personnel rooms clean, lockers provided, located, used.',
      35 => 'Other Operations: Separation from living/sleeping quarters. Laundry, clean or soiled linen properly stored.',
      36 => 'Conformance With Approved Procedures: Compliance with variance, specialized process, and HACCP plan',
      37 => 'Highly Susceptible Populations: Pasteurized foods used; prohibited foods not offered',
      38 => 'Consumer Advisory: Consumer advisory provided for raw or undercooked food',
    }

    descriptions[violation_id.to_i]
  end

end


# Execute as shell script if invoked directly.
if caller.empty?
  source_file = ARGV[0]

  if source_file.nil? || source_file.empty?
    puts "Usage: #{__FILE__} <scores_csv_file>"
    exit 1
  end

  LexToLIVES.new.transform(source_file)
end
