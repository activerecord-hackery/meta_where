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

    should "allow selection of join type in association joins" do
      assert_match /INNER JOIN/, @r.joins(:developers.inner).to_sql
      assert_match /LEFT OUTER JOIN/, @r.joins(:developers.outer).to_sql
    end

    should "only join once even if two join types are used" do
      assert_equal 1, @r.joins(:developers.inner, :developers.outer).to_sql.scan("JOIN").size
    end

    should "allow SQL functions via Symbol#func" do
      assert_equal @r.where(:name.in => ['Initech', 'Mission Data']), @r.joins(:developers).group('companies.id').having(:developers => {:count.func(:id).gt => 2}).all
    end

    should "allow SQL functions via Symbol#[]" do
      assert_equal @r.where(:name.in => ['Initech', 'Mission Data']), @r.joins(:developers).group('companies.id').having(:developers => {:count[:id].gt => 2}).all
    end

    should "allow SQL functions in select clause" do
      assert_equal [3,2,3], @r.joins(:developers).group('companies.id').select(:count[Developer.arel_table[:id]].as(:developers_count)).map {|c| c.developers_count}
    end

    should "allow operators on MetaWhere::Function objects" do
      assert_equal @r.where(:name.in => ['Initech', 'Mission Data']), @r.joins(:developers).group('companies.id').having(:developers => [:count[:id] > 2]).all
    end

    should "join multiple parameters to an SQL function with commas" do
      assert_match /concat\("companies"."id","companies"."name"\) LIKE '%blah%'/, @r.where(:concat[:id,:name].matches => '%blah%').to_sql
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

    should "behave as expected with empty arrays" do
      none = @r.where("3 = 1").all
      assert_equal none, @r.where(:name => []).all
      assert_equal none, @r.where(:name.in => []).all
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

    should "allow nested conditions hashes to have MetaWhere::Condition values" do
      assert_equal @r.joins(:data_types).where(:data_types => {:dec.gt => 2}).all,
                   @r.joins(:data_types).where(:data_types => :dec > 2).all
    end

    should "allow nested conditions hashes to have MetaWhere::And values" do
      assert_equal @r.joins(:data_types).where(:data_types => {:dec => 2..5}).all,
                   @r.joins(:data_types).where(:data_types => ((:dec >= 2) & (:dec <= 5))).all
    end

    should "allow nested conditions hashes to have MetaWhere::Or values" do
      assert_equal @r.joins(:data_types).where(:data_types => [:dec.gteq % 2 | :bln.eq % true]).all,
                   @r.joins(:data_types).where(:data_types => ((:dec >= 2) | (:bln >> true))).all
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

  context "A merged relation with a different base class" do
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

  context "A merged relation with a different base class and a MetaWhere::JoinType in joins" do
    setup do
      @r = Developer.where(:salary.gteq % 70000) & Company.where(:name.matches % 'Initech').joins(:data_types.outer)
    end

    should "merge the JoinType under the association for the merged relation" do
      assert_match /LEFT OUTER JOIN #{DataType.quoted_table_name} ON #{DataType.quoted_table_name}."company_id" = #{Company.quoted_table_name}."id"/,
                   @r.to_sql
    end
  end

  context "A merged relation with with a different base class and an alternate association" do
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

  context "A Developer relation" do
    setup do
      @r = Developer.scoped
    end

    should "allow a hash with another relation as a value" do
      query = @r.where(:company_id => Company.where(:name.matches => '%i%'))
      assert_match /IN \(1, 2, 3\)/, query.to_sql
      assert_same_elements Developer.all, query.all
    end

    should "merge multiple conditions on the same column and predicate with ORs" do
      assert_match /"developers"."name" = 'blah' OR "developers"."name" = 'blah2'/,
                   @r.where(:name => 'blah').where(:name => 'blah2').to_sql
      assert_match /"developers"."name" LIKE '%blah%' OR "developers"."name" LIKE '%blah2%'/,
                   @r.where(:name.matches => '%blah%').where(:name.matches => '%blah2%').to_sql
    end

    should "erge multiple conditions on the same column but different predicate with ANDs" do
      assert_match /"developers"."name" = 'blah' AND "developers"."name" LIKE '%blah2%'/,
                   @r.where(:name => 'blah').where(:name.matches => '%blah2%').to_sql
    end
  end

  context "A relation" do
    should "allow conditions on a belongs_to polymorphic association with an object" do
      dev = Developer.first
      assert_equal dev, Note.where(:notable.type(Developer) => dev).first.notable
    end

    should "allow conditions on a belongs_to association with an object" do
      company = Company.first
      assert_same_elements Developer.where(:company_id => company.id),
                           Developer.where(:company => company).all
    end

    should "allow conditions on a has_and_belongs_to_many association with an object" do
      project = Project.first
      assert_same_elements Developer.joins(:projects).where(:projects => {:id => project.id}),
                           Developer.joins(:projects).where(:projects => project)
    end

    should "not allow an object of the wrong class to be passed to a non-polymorphic association" do
      company = Company.first
      assert_raise ArgumentError do
        Project.where(:developers => company).all
      end
    end

    should "allow multiple AR objects on the value side of an association condition" do
      projects = [Project.first, Project.last]
      assert_same_elements Developer.joins(:projects).where(:projects => {:id => projects.map(&:id)}),
                           Developer.joins(:projects).where(:projects => projects)
    end

    should "allow multiple different kinds of AR objects on the value side of a polymorphic belongs_to" do
      dev1 = Developer.first
      dev2 = Developer.last
      project = Project.first
      company = Company.first
      assert_same_elements Note.where(
                                       {:notable_type => project.class.base_class.name, :notable_id => project.id} |
                                       {:notable_type => dev1.class.base_class.name, :notable_id => [dev1.id, dev2.id]} |
                                       {:notable_type => company.class.base_class.name, :notable_id => company.id}
                                     ),
                           Note.where(:notable => [dev1, dev2, project, company]).all
    end

    should "allow an AR object on the value side of a polymorphic has_many condition" do
      note = Note.first
      peter = Developer.first
      assert_equal [peter],
                   Developer.joins(:notes).where(:notes => note).all
    end

    should "allow a join of a polymorphic belongs_to relation with a type specified" do
      dev = Developer.first
      company = Company.first
      assert_equal [company.notes.first],
                   Note.joins(:notable.type(Company) => :developers).where(:notable => {:developers => dev}).all
    end

    should "allow selection of a specific polymorphic join by name in the where clause" do
      dev = Developer.first
      company = Company.first
      project = Project.first
      dev_note = dev.notes.first
      company_note = company.notes.first
      project_note = project.notes.first
      # Have to use outer joins since one inner join will cause remaining rows to be missing
      # This is pretty convoluted, and way beyond the normal use case for polymorphic belongs_to
      # joins anyway.
      @r = Note.joins(:notable.type(Company).outer => :notes.outer, :notable.type(Developer).outer => :notes.outer, :notable.type(Project).outer => :notes.outer)
      assert_equal [dev_note],
                    @r.where(:notable.type(Developer) => {:notes => dev_note}).all
      assert_equal [company_note],
                    @r.where(:notable.type(Company) => {:notes => company_note}).all
      assert_equal [project_note],
                    @r.where(:notable.type(Project) => {:notes => project_note}).all
    end

    should "maintain belongs_to conditions in a polymorphic join" do
      assert_match /1=1/, Note.joins(:notable.type(Company)).to_sql
    end
  end
end
