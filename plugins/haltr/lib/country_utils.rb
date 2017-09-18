module CountryUtils

  def country_alpha2
    country.upcase
  end

  def country_alpha3
    SunDawg::CountryIsoTranslater.translate_standard(country.upcase,"alpha2","alpha3")
  end

  def country_name
    c = ISO3166::Country[country]
    c.translations[I18n.locale.to_s] || c.name
  end
end
