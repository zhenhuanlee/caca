# == Schema Information
#
# Table name: wangwangs
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  account    :string(50)
#  state      :string(10)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_wangwangs_on_state    (state)
#  index_wangwangs_on_user_id  (user_id)
#

class Wangwang < ActiveRecord::Base
  include AASM
  belongs_to :user
  has_many :orders

  validates_presence_of :account
  validates :account, length: { in: 3..20 },
            uniqueness: {scope: :user_id, case_sensitive: false}, allow_blank: true

  aasm column: :state do
    state :pending, initial: true
    state :confirmed
    state :rejected

    event :reject do
      transitions from: :pending, to: :rejected
    end

    event :confirm do
      transitions from: :pending, to: :confirmed
    end
  end

  def day_count
    self.orders.where('created_at > ?', 1.days.ago).count
  end

  def week_count
    self.orders.where(user: self.user).where('created_at > ?', 7.days.ago).count
  end

  def month_count
    self.orders.where(user: self.user).where('created_at > ?', 30.days.ago).count
  end

  validate :wangwangs_count_within_limit, on: :create

  private
    def wangwangs_count_within_limit

      errors.add(:base, "最多可绑定50个旺旺帐号") if Wangwang.where(user: self.user).count >= 50
    end
end
