class OldProgramAnnouncedTimeMigration < ActiveRecord::Migration
  def up
    Program.all.each do |p|
      if p.announced?
        p.announced_timing = p.timings.collect(&:name).join(", ")
        p.save
      end
    end
  end

  def down

  end
end
