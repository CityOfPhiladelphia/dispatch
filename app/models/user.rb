# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  name                   :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  permission_level       :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ActiveRecord::Base
  # Used for subscriptions
  has_and_belongs_to_many :opportunities
  has_and_belongs_to_many :categories

  has_and_belongs_to_many :vendors

  devise :database_authenticatable,
         :confirmable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  enum permission_level: [:user, :staff, :approver, :admin]

  validates :name, presence: true

  before_create :set_staff_if_email_matches_staff_domain

  # https://github.com/plataformatec/devise/#activejob-integration
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def permission_level_is_at_least?(x)
    User.permission_levels[permission_level] >= User.permission_levels[x]
  end

  private

  def set_staff_if_email_matches_staff_domain
    if email_domain.in?(Rails.configuration.x.staff_domains)
      self.permission_level = 'staff'
    end
  end

  def email_domain
    email.split('@').last
  end
end
