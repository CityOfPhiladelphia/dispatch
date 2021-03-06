# == Schema Information
#
# Table name: saved_searches
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  search_params :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_saved_searches_on_user_id  (user_id)
#

require 'spec_helper'

describe SavedSearch do
  subject { build(:saved_search) }
  it { should be_valid }
end
