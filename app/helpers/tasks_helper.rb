require 'iconv'

module TasksHelper

  def n19_fix(string,n=40)
    string.to_ascii[0..n-1].upcase.ljust(n)
  end

end
