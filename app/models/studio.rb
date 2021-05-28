# frozen_string_literal: true

class Studio < ApplicationRecord
  include AASM
  include IdentityCache

  LANGUAGES = %w[
    Mandarin
    Spanish
    English
    Dutch
    Hindi
    Arabic
    Portuguese
    Russian
    Japanese
    German
    French
    Vietnamese
    Korean
    Italian
    Turkish
  ].freeze

  SERVICES = ['Tattoo Consultation', 'Aftercare Consultation',
              'Basic Body Modification', 'Piercing', 'Scarification',
              'Tattoo Coverup', 'Tattoo Design', 'Tattooing'].freeze

  searchkick locations: [:location]

  include AddressExtension
  extend FriendlyId
  friendly_id :slug_candidates, use: %i[slugged finders]

  include StatusManagement

  acts_as_favoritable
  belongs_to :user
  has_many :studio_invites, dependent: :destroy
  has_many :studio_artists
  has_many :artists, through: :studio_artists
  has_many :tattoos
  has_many :clients
  has_many :guest_artist_applications
  has_one_attached :avatar
  has_one_attached :hero_banner

  cache_index :slug, unique: true
  cache_has_many :studio_artists, embed: true

  validates :avatar, :hero_banner, size: { less_than: 10.megabytes, message: 'is not given between size' }

  validates :email, presence: true, on: :create
  validates :name, presence: true
  validates :user_id, uniqueness: true
  before_validation :validate_studio_time

  after_commit :upgrade_user_role, on: :create
  after_validation :save_location_data, if: :address_changed?
  after_save :send_phone_verification_code, if: :phone_number_changed?

  def slug_candidates
    [
      %i[name city state],
      %i[name city state country]
    ]
  end

  def add_artist(artist_id)
    studio_artists.create(artist_id: artist_id)
  end

  def search_data
    attributes.merge(location: { lat: lat, lon: lon })
  end

  def search_profile_image
    tattoos.first&.image || hero_banner
  end

  def city_state
    format('%s %s', city, state)
  end

  def full_address
    format('%s %s %s %s %s', street_address, city, state, country, zip_code)
  end

  def verify_phone(code)
    status = PhoneNumberService.new(code: code, phone_number: phone_number).status

    update(phone_verified: true) if status == 'approved'
  end

  def self.create_studio(user, params)
    studio_params = params.merge(params[:working_hours]).delete_if { |k, _v| k == 'working_hours' }

    user.build_studio(studio_params)
  end

  def has_social_profiles
    instagram_url.present? || facebook_url.present? || twitter_url.present?
  end

  def has_avatar
    avatar.present?
  end

  def has_tattoo_gallery
    tattoos.present?
  end

  private

  def send_phone_verification_code
    PhoneNumberService.new(phone_number: phone_number).verify
  end

  def upgrade_user_role
    user.assign_role(User.roles[:studio_manager])
  end

  def validate_studio_time
    %w[monday tuesday wednesday thursday friday saturday sunday].each do |time|
      next unless self["#{time}_start".to_sym] || self["#{time}_end".to_sym]

      validates_time "#{time}_start".to_sym,
                     before: "#{time}_end".to_sym,
                     before_message: "must be before #{time} end date"
    end
  end
end
