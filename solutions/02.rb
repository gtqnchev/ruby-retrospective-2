class Collection
  include Enumerable

  attr_accessor :songs

  def initialize(songs = [])
    @songs = songs
  end

  def self.parse(text)
    text.split("\n\n").inject(Collection.new) do |collection, song|
      name, artist, album = song.split("\n")
      collection.songs << Song.new(name, artist, album)
      collection
    end
  end

  def names
    songs.map { |song| song.name }.uniq
  end

  def artists
    songs.map { |song| song.artist }.uniq
  end

  def albums
    songs.map { |song| song.album }.uniq
  end

  def filter(criteria)
    collection = songs.select { |song| criteria.match?(song) }
    Collection.new(collection)
  end

  def adjoin(collection)
    Collection.new(songs.concat(collection.songs).uniq)
  end

  def each
    songs.each { |song| yield song }
  end
end

class SubCriteria
  attr_accessor :name, :artist, :album

  def initialize
    @name = { valid: [], invalid: [] }
    @artist = { valid: [], invalid: [] }
    @album = { valid: [], invalid: [] }
  end

  def &(other)
    name.merge!(other.name) { |key, oldval, newval| oldval | newval }
    artist.merge!(other.artist) { |key, oldval, newval| oldval | newval }
    album.merge!(other.album) { |key, oldval, newval| oldval | newval }
    self
  end

  def !
    name[:valid], name[:invalid] = name[:invalid], name[:valid]
    artist[:valid], artist[:invalid] = artist[:invalid], artist[:valid]
    album[:valid], album[:invalid] = album[:invalid], album[:valid]
    self
  end

  def name_match?(song)
    valid = name[:valid]
    invalid = name[:invalid]
    return false if invalid.include?(song.name) || valid.length > 1
    valid.empty? || valid.include?(song.name)
  end

  def artist_match?(song)
    valid = artist[:valid]
    invalid = artist[:invalid]
    return false if invalid.include?(song.artist) || valid.length > 1
    valid.empty? || valid.include?(song.artist)
  end

  def album_match?(song)
    valid = album[:valid]
    invalid = album[:invalid]
    return false if invalid.include?(song.album) || valid.length > 1
    valid.empty? || valid.include?(song.album)
  end
end

class Criteria
  attr_accessor :list

  def initialize(list = [])
    @list = list
  end

  def &(other)
    criteria = list.product(other.list).map do |criteria|
      criteria.inject(SubCriteria.new, :&)
    end
    Criteria.new(criteria)
  end

  def |(other)
    criteria = list + other.list
    Criteria.new(criteria)
  end

  def !
    sub_criteria = list.inject(SubCriteria.new, :&)
    Criteria.new([!sub_criteria])
  end

  def self.name(text)
    sub_criteria = SubCriteria.new
    sub_criteria.name[:valid] << text
    Criteria.new([sub_criteria])
  end

  def self.artist(text)
    sub_criteria = SubCriteria.new
    sub_criteria.artist[:valid] << text
    Criteria.new([sub_criteria])
  end

  def self.album(text)
    sub_criteria = SubCriteria.new
    sub_criteria.album[:valid] << text
    Criteria.new([sub_criteria])
  end

  def match?(song)
    list.any? do |sub_criteria|
      sub_criteria.name_match?(song) &&
      sub_criteria.artist_match?(song) &&
      sub_criteria.album_match?(song)
    end
  end
end

class Song
  attr_accessor :name, :artist, :album

  def initialize(name, artist, album)
    @name, @artist, @album = name, artist, album
  end
end