require 'money'
require 'active_record_extension'

# This tells the Active Record extension what class to use to represent
# Money. You can change it to anything you want, as long as it can be 
# initialized with a +Fixnum+ that represents a price in cents.
RailsMoney::MONEY_CLASS = Money