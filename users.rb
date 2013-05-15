# users.rb
# Mirc pipeline processor
# This aids in creation of a MIRC users.xml
# Edit this file to create an instance variable @people
# that contains a Person with attributes
# username, password and an array of roles

require 'erb'
require 'csv'
require 'digest/md5'

b = binding
template_file = "users.erb"

# Available roles
# ['admin', 'author', 'publisher']

def hash_password(password)
	require 'digest/md5'
	password_hash = Digest::MD5.hexdigest("password goes here")
	password_hash.hex
end

Person = Struct.new(:username, :roles, :hashed_password)

@people = []

CSV.foreach('./userlist.csv') do |row|

  # Obviously this is an insecure password.  include something real in your .csv file and pick the right row
  # If you use LDAP - this password is ignored.
 
  @people << Person.new(row[2].split("@")[0], ['author', 'department'], hash_password('password'))

end

template = ERB.new(File.read(template_file))

puts template.result(b)