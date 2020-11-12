class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  field :allowed_postcodes_lsoa, type: :array
  field :specific_allowed_postcodes, type: :array
end
