require 'helper'

class TestBase < Test::Unit::TestCase
  should "raise an exception when MetaWhere::Columns are in :conditions of an association" do
    assert_raises MetaWhere::MetaWhereInAssociationError do
      InvalidCompany.all
    end
  end

  should "raise an exception when MetaWhere::Conditions are in :conditions of an association" do
    assert_raises MetaWhere::MetaWhereInAssociationError do
      InvalidDeveloper.all
    end
  end
end
