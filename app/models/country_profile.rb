class CountryProfile < ApplicationRecord
  validates :code, presence: true, uniqueness: true
end
