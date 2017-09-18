class Mandate < ActiveRecord::Base


  belongs_to :client
  validates_presence_of :client
  validate :signed_doc_is_pdf
  attr_protected :created_at, :updated_at

  attr_accessor :signed_doc_content_type, :delete_signed_doc

  before_save do
    if delete_signed_doc == "1" and !signed_doc_changed?
      write_attribute(:signed_doc, nil)
    end
  end

  after_initialize do
    self.sepa_type ||= "core"
    self.recurrent = true if self.recurrent.nil?
  end

  def signed_doc=(s)
    if s and s.size > 0
      self.signed_doc_content_type = s.content_type
      write_attribute(:signed_doc, Haltr::Utils.compress(s.read))
    end
  end

  def signed_doc
    Haltr::Utils.decompress(read_attribute(:signed_doc))
  end

  def signed_doc_filename
    "signed_mandate.pdf"
  end

  private

  def signed_doc_is_pdf
    if signed_doc_content_type and signed_doc_content_type != "application/pdf"
      errors.add(:signed_doc, "is not a PDF")
    end
  end

end
