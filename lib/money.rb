# Simple Money class. 
# This stores the value of the price in cents, and can be initialized with
# a Float (dollars.cents) or Fixnum (cents). 
# 
# If you need something more indepth, that deals with currency, exchange rates,
# I highly recommend replacing this with the Money class Tobi wrote, 
# which you can get in Gems (gem install money). 
#
# The following article by Martin Fowler was used as a reference:
#   http://www.martinfowler.com/ap2/quantity.html

class MoneyError < StandardError; end;
class Money
  include Comparable
  attr_reader :cents

  # Create a new Money object with value. Value can be a Float or Fixnum.
  def initialize(value)
    unless [Float,Fixnum,NilClass].include? value.class
      raise MoneyError, "Cannot create money from #{value.class}. Float or Fixnum required." 
    end    
    value = (value*100).round if value.kind_of? Float
    value = 0 if value.kind_of? NilClass
    @cents = value
  end

  # Equality. 
  def eql?(other)
   (cents <=> other.cents)
  end

  # Equality for Comparable.
  def <=>(other)
    eql?(other)
  end

  # Add Fixnum, Float, or Money and return result as a Money object
  def +(other)
    Money.new(cents + other.to_money.cents)
  end

  # Subtract Fixnum, Float, or Money and return result as a Money object
  def -(other)
    Money.new(cents - other.to_money.cents)
  end
  
  # Multiply by fixnum and return result as a Money object
  def *(other)
    Money.new((cents * other.to_f) / 100)
  end
  
  # Divide by fixnum and return result as a Money object
  def /(denominator)
    raise MoneyError, "Denominator must be a Fixnum. (#{denominator} is a #{denominator.class})"\
      unless denominator.is_a? Fixnum

    result = []
    equal_division = (cents / denominator).round
    denominator.times { result << Money.new(equal_division) }
    extra_pennies = cents - (equal_division * denominator)
    
    # Make sure we don't loose any pennies!
    extra_pennies.times { |p| result[p] += 1 }
    result
  end
  
  # Is this free?
  def free?
    return (cents == 0)
  end
  alias zero? free?

  # Return the value in cents
  def cents
    @cents
  end  

  # Return the value in dollars
  def dollars
    cents.to_f / 100
  end

  # Return the value in a string (in dollars)
  def to_s
    return "free" if free?
    "$#{sprintf("%.2f",dollars)}"
  end

  # Conversation to self
  def to_money
    self
  end

end

class Numeric
  # Creates a new money object with the value of the +Numeric+ object.
  #   100.to_money => #<Money @cents=100>
  #   100.00.to_money => #<Money @cents=10000>
  #   100.37.to_money => #<Money @cents=10037>
  def to_money
    Money.new(self)
  end
end

