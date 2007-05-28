# Money class. 
# This stores the value of the price in cents, and can be initialized with
# a Float (dollars.cents) or Fixnum (dollars). To create a money object from
# cents, use create_from_cents (Money.create_from_cents(500) and Money.new(5) are
# the same)
#
# The following article by Martin Fowler was used as a reference:
#   http://www.martinfowler.com/ap2/quantity.html

raise "Another Money Object is already defined!" if Object.const_defined?(:Money)

class MoneyError < StandardError; end;
class Money
  include Comparable
  attr_reader :cents

  # Create a new Money object with value. Value can be a Float (Dollars.cents) or Fixnum (Dollars).
  def initialize(value)
    unless [Float,Fixnum,NilClass].include? value.class
      raise MoneyError, "Cannot create money from #{value.class}. Float or Fixnum required." 
    end 
    value = value.kind_of?(NilClass) ? 0 : (value*100.0).round
    @cents = value
  end

  # Create a new Money object with a value representing cents.
  def self.create_from_cents(value)
    unless [Fixnum,NilClass].include? value.class
      raise MoneyError, "Cannot create money from cents with #{value.class}. Fixnum required." 
    end
    return value.nil? ? Money.new(0) : Money.new(value/100.0)
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
    Money.create_from_cents((cents + other.to_money.cents))
  end

  # Subtract Fixnum, Float, or Money and return result as a Money object
  def -(other)
    Money.create_from_cents((cents - other.to_money.cents))
  end
  
  # Multiply by fixnum and return result as a Money object
  def *(other)
    Money.create_from_cents((cents * other).round)
  end
  
  # Divide by fixnum and return result as a Money object
  def /(denominator)
    raise MoneyError, "Denominator must be a Fixnum. (#{denominator} is a #{denominator.class})"\
      unless denominator.is_a? Fixnum

    result = []
    equal_division = (cents / denominator).round
    denominator.times { result << Money.create_from_cents(equal_division) }
    extra_pennies = cents - (equal_division * denominator)
    
    # Make sure we don't loose any pennies!
    extra_pennies.times { |p| result[p] += 0.01 }
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

