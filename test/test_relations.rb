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

    should "create new records with values from equality predicates" do
      assert_equal "New Company",
                   @r.where(:name => 'New Company').new.name
      assert_equal "New Company",
                   @r.where(:name.eq => 'New Company').new.name
      assert_equal "New Company",
                   @r.where(:name.eq % 'New Company').new.name
    end

    should "create new records with values from equality predicates using last supplied predicate" do
      assert_equal "Newer Company",
                   @r.where(:name => 'New Company').where(:name => 'Newer Company').new.name
      assert_equal "Newer Company",
                   @r.where(:name.eq => 'New Company').where(:name.eq => 'Newer Company').new.name
      assert_equal "Newer Company",
                   @r.where(:name.eq % 'New Company').where(:name.eq % 'Newer Company').new.name
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

    context "with eager-loaded developers" do
      setup do
        @r = @r.includes(:developers).where(:developers => {:name => 'Ernie Miller'})
      end

      should "return the expected result" do
        assert_equal Company.where(:name => 'Mission Data'), @r.all
      end

      should "generate debug SQL with the joins in place" do
        assert_match /LEFT OUTER JOIN "developers"/, @r.debug_sql
      end
    end
  end

  context "A relation from an STI class" do
    setup do
      @r = TimeAndMaterialsProject.scoped
    end

    should "return results from the designated class only" do
      assert_equal 2, @r.size
      assert @r.all? {|r| r.is_a?(TimeAndMaterialsProject)}
    end

    should "inherit the default scope of the parent class" do
      assert_match /IS NOT NULL/, @r.to_sql
    end

    should "allow use of scopes in the parent class" do
      assert_equal 1, @r.hours_lte_100.size
      assert_equal 'MetaSearch Development', @r.hours_lte_100.first.name
    end
  end

  context "A merged relation" do
    setup do
      @r = Developer.where(:salary.gteq % 70000) & Company.where(:name.matches % 'Initech')
    end

    should "keep the table of the second relation intact in the query" do
      assert_match /#{Company.quoted_table_name}."name"/, @r.to_sql
    end

    should "return expected results" do
      assert_equal ['Peter Gibbons', 'Michael Bolton'], @r.all.map(&:name)
    end
  end

  context "A merged relation with an alternate association" do
    setup do
      @r = Company.scoped.merge(Developer.where(:salary.gt => 70000), :slackers)
    end

    should "use the proper association" do
      assert_match Company.joins(:slackers).where(:slackers => {:salary.gt => 70000}).to_sql,
                   @r.to_sql
    end

    should "return expected results" do
      assert_equal ['Initech', 'Advanced Optical Solutions'], @r.all.map(&:name)
    end
  end

  context "A Person relation" do
    setup do
      @r = Person.scoped
    end

    context "with self-referencing joins" do
      setup do
        @r = @r.where(:children => {:children => {:name => 'Jacob'}}).joins(:children => :children)
      end

      should "join the table multiple times with aliases" do
        assert_equal 2, @r.to_sql.scan('INNER JOIN').size
        assert_match /INNER JOIN "people" "children_people"/, @r.to_sql
        assert_match /INNER JOIN "people" "children_people_2"/, @r.to_sql
      end

      should "place the condition on the correct join" do
        assert_match /"children_people_2"."name" = 'Jacob'/, @r.to_sql
      end

      should "return the expected result" do
        assert_equal Person.where(:name => 'Abraham'), @r.all
      end
    end

    context "with self-referencing joins on parent and children" do
      setup do
        @r = @r.where(:children => {:children => {:parent => {:parent => {:name => 'Abraham'}}}}).
                joins(:children => {:children => {:parent => :parent}})
      end

      should "join the table multiple times with aliases" do
        assert_equal 4, @r.to_sql.scan('INNER JOIN').size
        assert_match /INNER JOIN "people" "children_people"/, @r.to_sql
        assert_match /INNER JOIN "people" "children_people_2"/, @r.to_sql
        assert_match /INNER JOIN "people" "parents_people"/, @r.to_sql
        assert_match /INNER JOIN "people" "parents_people_2"/, @r.to_sql
      end

      should "place the condition on the correct join" do
        assert_match /"parents_people_2"."name" = 'Abraham'/, @r.to_sql
      end

      should "return the expected result" do
        assert_equal Person.where(:name => 'Abraham'), @r.all
      end
    end
  end
end
