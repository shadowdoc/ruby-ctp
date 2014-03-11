# create_lookup.rb
# This script takes a DORIS-style .csv file and processes it into the lookup original format for CTP
#
# This also creates a .csv file for the radiance script to use to trigger C-MOVE events.

require 'csv'
require 'securerandom'
require 'digest/md5'

DEBUG = true

irb = 1307011922
primary_investigator = "Dr. Dalsing - Vascular Surgery"
contact = "Adam Gracon <agracon@iupui.edu>"
salt = SecureRandom.base64

unless ARGV.length ==  1 && File.exists?(ARGV[0])
	raise "ERROR: Please include an existing CSV file as the first argument"
end

filename = ARGV[0].split(".")

patients = []
accessions = []
new_accessions = []

original = CSV.read(ARGV[0], :headers => true)

original.each do |row|
	# There is an issue with DORIS exports where the MRN is treated as a number rather than a string
	# This leads to truncation of numbers that start with 0.  MRN should be an 8 character string
	patients << row['mrn'].to_s.rjust(8,"0")
	accessions << row['acc']
end

# Get rid of duplicates
patients.uniq!
accessions.uniq!

# Create the new_patients hash
# This stores our old MRNs (key) and the Study MRNs (value)

new_patients = {}

patients.each_with_index do |p,i|

	# For patient with MRN 93747 and IRB 9876543210 that is the first in the list
	# this would produce the following line
	# ptid/93747=9876543210-101

	new_patients[p] = "#{irb}-#{100 + i}"

end

# Create the new_accessions hash
# This stores our old accession (key) and the Study Accession (value)

new_accessions = {}

accessions.each_with_index do |a,i|

	new_accessions[a] = "#{irb}-#{10000 + i}" 

end

# Rewrite the CSV file including the new info
CSV.open(filename[0] + "-updated." + filename[1], 'w') do |csv_out|

	# add the headers to our new csv file
	csv_out << original.headers + ['study_id', 'study_accession']

	# Add two new columns
	original.each do |row|
		csv_out << row.fields + [new_patients[row['mrn']], new_accessions[row['acc']] ]
	end

end

# Write the lookup properties and accessions files

File.open("#{irb}-lookup.properties", 'w') do |f|
	File.open("#{irb}-accessions", 'w') do |c|

		f.puts("# IRB: #{irb}")
		f.puts("# PI: #{primary_investigator}")
		f.puts("# Created on #{Time.now}")
		
		new_patients.each do |old_p, new_p|

			output = "ptid/#{old_p}=#{new_p}"
			puts output if DEBUG
			f.puts output
		end

		# The lookup original for accession numbers just identifies the IRB that's associated with a particular study
		# Synapse uses the IRB number previx as a trigger to sort

		new_accessions.each do |old_a, new_a|

		    output = "acc/#{old_a}=#{new_a}"
			puts output if DEBUG
			f.puts output

			# This writes to the accession list
			c.puts old_a
		end
	end
end

raise "ERROR: Accession Number Hashing failed all entries are not unique" if new_accessions.values.uniq != new_accessions.values