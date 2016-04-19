# == Schema Information
#
# Table name: opportunities
#
#  id                      :integer          not null, primary key
#  created_by_user_id      :integer
#  title                   :string
#  description             :text
#  department_id           :integer
#  contact_name            :string
#  contact_email           :string
#  contact_phone           :string
#  submission_adapter_name :string
#  submission_adapter_data :text
#  publish_at              :datetime
#  submissions_open_at     :datetime
#  submissions_close_at    :datetime
#  enable_questions        :boolean          default(FALSE), not null
#  questions_open_at       :datetime
#  questions_close_at      :datetime
#  approved_at             :datetime
#  approved_by_user_id     :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_opportunities_on_department_id  (department_id)
#

class Opportunity < ActiveRecord::Base
  belongs_to :created_by_user, class_name: 'User'
  belongs_to :approved_by_user, class_name: 'User'
  belongs_to :department

  has_and_belongs_to_many :categories
  has_many :questions

  serialize :submission_adapter_data, Hash

  scope :not_approved, -> { where('approved_at IS NULL') }
  scope :approved, -> { where('approved_at IS NOT NULL') }
  scope :published, -> {
    where('publish_at IS NULL OR publish_at < ?', Time.now)
  }
  scope :posted, -> { approved.published }

  scope :order_by_recently_posted, -> {
    order('GREATEST(publish_at, approved_at) DESC')
  }

  scope :submissions_open, -> {
    where('submissions_close_at IS NULL OR submissions_close_at > ?', Time.now)
  }

  scope :submissions_closed, -> {
    where('submissions_close_at IS NOT NULL AND submissions_close_at < ?', Time.now)
  }

  scope :with_category, -> (category_id) {
    return unless category_id.to_s.match(/\A[0-9]+\Z/)

    where(%Q{
      (SELECT categories_opportunities.category_id
      FROM categories_opportunities
      WHERE categories_opportunities.opportunity_id = opportunities.id
      AND categories_opportunities.category_id = ?
      LIMIT 1) IS NOT NULL
    }, category_id)
  }

  validates :title, presence: true
  validates :created_by_user, presence: true

  delegate :submission_page,
           :view_proposals_url,
           :view_proposals_instructions,
           :submit_proposals_url,
           :submit_proposals_instructions,
           :has_submission_method?,
           to: :submission_adapter

  before_create :set_default_submission_adapter_name,
                :set_default_contact_info

  def posted?
    approved? && published?
  end

  def approved?
    approved_at.present?
  end

  def approve!
    update approved_at: Time.now
  end

  def unapprove!
    update approved_at: nil
  end

  def published?
    !publish_at ||
    publish_at < Time.now
  end

  def posted_at
    [
      publish_at,
      approved_at
    ].compact.max
  end

  def to_param
    "#{id}-#{title.parameterize}"
  end

  def submission_adapter
    if submission_adapter_name.present?
      "SubmissionAdapters::#{submission_adapter_name}".constantize.new(self)
    else
      default_submission_adapter
    end
  rescue
    default_submission_adapter
  end

  def open_for_submissions?
    (!submissions_open_at || submissions_open_at < Time.now) &&
    (!submissions_close_at || submissions_close_at > Time.now)
  end

  def open_for_questions?
    enable_questions? &&
    (!questions_open_at || questions_open_at < Time.now) &&
    (!questions_close_at || questions_close_at > Time.now)
  end

  private

  def default_submission_adapter
    SubmissionAdapters::None.new(self)
  end

  def set_default_submission_adapter_name
    self.submission_adapter_name ||= default_submission_adapter.
                                      class.
                                      to_adapter_name
  end

  def set_default_contact_info
    self.contact_name ||= created_by_user.name
    self.contact_email ||= created_by_user.email
  end
end
