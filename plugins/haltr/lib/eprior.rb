class Eprior
  SCHEMEIDS= {
    "GLN"      =>  "EAN International",
    "NAL"   =>  "NAL"
  }

  def self.schemes_for_select
    r = {'None'=>''}
    SCHEMEIDS.each do |k,v|
      r["#{k} - #{v}"] = k
    end
    return r
  end
end
