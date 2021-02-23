class Article < ApplicationRecord
  enum status: {
    draft: 'draft',
    published: 'published',
    flagged: 'flagged'
  }

  searchkick word_start: %i[title page_title slug meta_description introduction content tag_list]

  belongs_to :user
  extend FriendlyId
  friendly_id :title, use: :slugged

  validates :title, :page_title, :meta_description, :introduction, :content, :slug, :status, presence: true

  before_validation :assign_status, only: %i[create update]
  before_validation :import_tag_list, only: %i[create update]

  def assign_status
    self.status = Article.statuses[status] || Article.statuses[:draft]
  end

  def import_tag_list
    self.tag_list = JSON.parse(tag_list).uniq.join(',')
  end
end
