require 'helper'

class TestRelations < Test::Unit::TestCase
  context "A company relation" do
    setup do
      @r = Company.scoped
    end
    
    should "behave as expected with one-level hash params" do
      results = @r.where(:name => 'Initech')
      assert_equal 1, results.size
      assert_equal results.first, Company.find_by_name('Initech')
    end
    
    should "behave as expected with nested hash params" do
      results = @r.where(
        :developers => {
          :name => 'Peter Gibbons',
          :notes => {
            :note => 'A straight shooter with upper management written all over him.'
          }
        }
      )
      assert_raises ActiveRecord::StatementInvalid do
        results.all
      end
      results = results.joins(:developers => :notes)
      assert_equal 1, results.size
      assert_equal results.first, Company.find_by_name('Initech')
    end
    
    should "behave as expected with SQL interpolation" do
      results = @r.where('name like ?', '%tech')
      assert_equal 1, results.size
      assert_equal results.first, Company.find_by_name('Initech')
    end
    
    should "behave as expected with mixed hash and SQL interpolation" do
      results = @r.where('name like ?', '%tech').where(:created_at => 100.years.ago..Time.now)
      assert_equal 1, results.size
      assert_equal results.first, Company.find_by_name('Initech')
    end
    
    should "allow multiple condition params in a single where" do
      results = @r.where(['name like ?', '%tech'], :created_at => 100.years.ago..Time.now)
      assert_equal 1, results.size
      assert_equal results.first, Company.find_by_name('Initech')
    end
    
    should "allow predicate method selection on hash keys" do
      assert_equal @r.where(:name.eq => 'Initech').all, @r.where(:name => 'Initech').all
      assert_equal @r.where(:name.matches => 'Mission%').all, @r.where('name LIKE ?', 'Mission%').all
    end
    
    should "allow operators to select predicate methods" do
      assert_equal @r.where(:name ^ 'Initech').all, @r.where('name != ?', 'Initech').all
      assert_equal @r.where(:id + [1,3]).all, @r.where('id IN (?)', [1,3]).all
      assert_equal @r.where(:name =~ 'Advanced%').all, @r.where('name LIKE ?', 'Advanced%').all
    end
    
    should "use % 'substitution' for hash key predicate methods" do
      assert_equal @r.where(:name.like % 'Advanced%').all, @r.where('name LIKE ?', 'Advanced%').all
    end
    
    should "allow | and & for compound predicates" do
      assert_equal @r.where(:name.like % 'Advanced%' | :name.like % 'Init%').all,
                   @r.where('name LIKE ? OR name LIKE ?', 'Advanced%', 'Init%').all
      assert_equal @r.where(:name.like % 'Mission%' & :name.like % '%Data').all,
                   @r.where('name LIKE ? AND name LIKE ?', 'Mission%', '%Data').all
    end
    
    should "allow nested conditions hashes to have array values" do
      assert_equal @r.joins(:data_types).where(:data_types => {:dec => 2..5}).all,
                   @r.joins(:data_types).where(:data_types => [:dec >= 2, :dec <= 5]).all
    end
    
    should "allow combinations of options that no sane developer would ever try to use" do
      assert_equal @r.find_all_by_name('Initech'),
                   @r.joins(:data_types, :developers => [:projects, :notes]).
                     where(
                      {
                        :data_types => [:dec > 3, {:bln.eq => true}]
                      } &
                      {
                        :developers => {
                          :name.like => 'Peter Gibbons'
                        }
                      } &
                      {
                        :developers => {
                          :projects => {
                            :estimated_hours.gteq => 1000
                          },
                          :notes => [:note.matches % '%straight shooter%']
                        }
                      }
                     ).uniq
    end
    
    should "autojoin associations when requested" do
      assert_equal @r.find_all_by_name('Initech'),
                   @r.where(
                     {
                       :data_types => [:dec > 3, {:bln.eq => true}]
                     } &
                     {
                       :developers => {
                         :name.like => 'Peter Gibbons'
                       }
                     } &
                     {
                       :developers => {
                         :projects => {
                           :estimated_hours.gteq => 1000
                         },
                         :notes => [:note.matches % '%straight shooter%']
                       }
                     }
                   ).autojoin.uniq
    end
    
    should "allow ordering by attributes in ascending order" do
      last_created = @r.all.sort {|a, b| a.created_at <=> b.created_at}.last
      assert_equal last_created, @r.order(:created_at.asc).last
    end
    
    should "allow ordering by attributes in descending order" do
      last_created = @r.all.sort {|a, b| a.created_at <=> b.created_at}.last
      assert_equal last_created, @r.order(:created_at.desc).first
    end
    
    should "allow ordering by attributes on nested associations" do
      highest_paying = Developer.order(:salary.desc).first.company
      assert_equal highest_paying, @r.joins(:developers).order(:developers => :salary.desc).first
    end
    
    should "autojoin based on ordering by attributes on nested associations" do
      highest_paying = Developer.order(:salary.desc).first.company
      assert_equal highest_paying, @r.order(:developers => :salary.desc).autojoin.first
    end
  end
end
