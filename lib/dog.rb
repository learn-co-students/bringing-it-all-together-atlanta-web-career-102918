require 'pry'

class Dog
  attr_reader :id
  attr_accessor :name, :breed
  def initialize(id: nil, name:, breed:)
    @id = id
    @name = name
    @breed = breed

  end

  def self.new_from_db(row)
    dog = self.new(id: row[0], name: row[1], breed: row[2])
  end

  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT
        breed TEXT
      )
    SQL
      DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
      DROP TABLE IF EXISTS dogs
    SQL

    DB[:conn].execute(sql)
  end

  def save
    if self.id
      self.update
    else
      sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL
      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
      self
    end


  end

  def update
    sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

  def self.create(hash)
    dog = self.new(name: hash[:name], breed: hash[:breed])
    dog.save
    dog
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?
    SQL
    dog = DB[:conn].execute(sql, id)[0]
    self.new(id: dog[0], name: dog[1], breed: dog[2])
  end

                            #search by hash
  def self.find_or_create_by(name:, breed:)
    #store search in variable.  It returns a nested array of the row

    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
    # test to see if dog exists, if so update it
    if !dog.empty?
      dog_data = dog[0]
      dog = self.new(name: dog_data[1], breed: dog_data[2], id: dog_data[0])
      #create new one if doesn't exist
    else
      dog = self.create(name: name, breed: breed)
    end
    #return the dgo
    dog
  end

  def self.find_by_name(name_arg)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?
    SQL
    DB[:conn].execute(sql, name_arg).map do|row|
      self.new_from_db(row)
    end.first
  end



end
