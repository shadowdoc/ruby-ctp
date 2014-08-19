# create_lookup.rb
# This script takes a DORIS-style .csv file and processes it into the lookup original format for CTP
#
# This also creates a .csv file for the radiance script to use to trigger C-MOVE events.

require 'csv'
require 'securerandom'
require 'digest/md5'

DEBUG = true

irb = 'xxxxxxxxx'
primary_investigator = "XXXXXXXXXXX"
contact = "XXXXXXXXXXXXXX"
salt = SecureRandom.base64
random_patient_id = true
random_accession_id = true

unless ARGV.length ==  1 && File.exists?(ARGV[0])
	raise "ERROR: Please include an existing CSV file as the first argument"
end

filename = ARGV[0].split(".")

patients = []
accessions = []

def create_random_list(l)
	# This creates a random list of numbers of lenght l
	# The numbers range from 100-10000

	random_limit = 1000
	a = (1...random_limit).sort_by{rand}
	a[0..l]
end

original = CSV.read(ARGV[0], :headers => true)

original.each do |row|
	# There is an issue with DORIS exports where the MRN is treated as a number rather than a string
	# This leads to truncation of numbers that start with 0.  MRN should be an 8 character string
	row['mrn']  = row['mrn'].to_s.rjust(8,"0")

	patients << row['mrn']
	accessions << row['acc']
end

# Get rid of duplicates
patients.uniq!
accessions.uniq!


# This is a safety thing based on the way that the random numbers are assigned.
# This could obviosly be fixed if needed.

if patients.length > 1000 || accessions.length > 1000
	raise "ERROR: Can't work with patient or accession lists larger than 10000"
end

# Create the new_patients hash
# This stores our old MRNs (key) and the Study MRNs (value)

new_patients = {}

if random_patient_id
	
	# This creates a random list of new IDs
	new_id_list = create_random_list(patients.length)

else

	# This creates a sequential list of new IDs
	new_id_list = (100...patients.length)

end

patients.each_with_index do |p,i|

	# For patient with MRN 93747 and IRB 9876543210 that is the first in the list
	# this would produce the following line if we're using non-random IDs
	# ptid/93747=9876543210-101

	# If we're using random IDs then 101 would be replaced with a random number 
	# between 100 and 10000 + length of the patient list

	puts "Old ID: #{p}, New ID: #{new_id_list[i]}" if DEBUG

	new_patients[p] = "#{irb}-#{new_id_list[i].to_s.rjust(4,"0")}"

end

# Here we check the results of our work to make sure that we don't have any duplicates
raise "ERROR: Patient Number Generation failed all entries are not unique" if new_patients.values.uniq != new_patients.values

# Create the new_accessions hash
# This stores our old accession (key) and the Study Accession (value)

new_accessions = {}

if random_accession_id
	
	# This creates a random list of new IDs
	new_id_list = create_random_list(accessions.length)

else

	# This creates a sequential list of new IDs
	new_id_list = (100...accessions.length)

end

accessions.each_with_index do |a,i|

	# This creates a hash with the new accession numbers
	# the old accession number is stored as the key, and the new as the value

	new_accessions[a] = "#{irb}-#{new_id_list[i].to_s.rjust(4, "0")}" 


	raise "ERROR: Accession Number too long for DICOM standard" if new_accessions[a].length > 16

end

# Rewrite the CSV file including the new info
CSV.open(filename[0] + "-with-deidentification-key." + filename[1], 'w') do |csv_out|

	# add the headers to our new csv file
	csv_out << original.headers + ['study_id', 'study_accession']

	# Add two new columns
	original.each do |row|
		csv_out << row.fields + [new_patients[row['mrn']], new_accessions[row['acc']] ]
	end

end

# Write the lookup properties and accessions files

File.open("#{irb}-lookup.properties", 'w') do |f|
	File.open("#{irb}-accessions.csv", 'w') do |c|

		f.puts("# IRB: #{irb}")
		f.puts("# PI: #{primary_investigator}")
		f.puts("# Created on #{Time.now}")
		
		new_patients.each do |old_p, new_p|

			output = "ptid/#{old_p}=#{new_p}"
			puts output if DEBUG
			f.puts output
		end

		# The lookup original for accession numbers just identifies the IRB that's associated with a particular study
		# Synapse uses the IRB number prefix as a trigger to sort into worklists

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