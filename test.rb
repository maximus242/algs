# Requires Octokit, run: gem install octokit

# 1. Count the number of duplicates

def duplicates(string)
  character_hash_map = string.downcase.chars.group_by { |char| char }
  character_hash_map.count do |character, value|
    value.count > 1
  end
end

puts duplicates("ABBA") == 2
puts duplicates("abcde") == 0
puts duplicates("aabBcde") == 2
puts duplicates("aabbcde") == 2
puts duplicates("indivisibility") == 1
puts duplicates("indivisibilities") == 2
puts duplicates("aA11") == 2

# 2. Digital root is the recursive sum of all the digits in a number

def digital_root(number)
  while number > 9 do
    number = number.digits.sum
  end

  return number
end

puts digital_root(16) == 7
puts digital_root(942) == 6
puts digital_root(132189) == 6
puts digital_root(493193) == 2

# 3. Github API Navigator

require 'octokit'

class GitHub
  attr_accessor :data 

  def client
    @client ||= Octokit::Client.new 
  end

  def method_missing(m, *args, &blk)
    if @data&.key? m
      @data[m]
    else
      super
    end
  end
end

class User < GitHub
  def initialize(username:, data: nil)
    @username, @data = username, data
  end

  def self.by_username(username)
    new(username: username)
  end

  def repos
    @repos ||= Repo.find_by_user(data.login)
  end

  def followers
    @followers ||= fetch_followers
  end

  def organizations
    @organizations ||= fetch_organizations
  end

  def data
    @data ||= client.user @username
  end

  private 

  def fetch_followers
    client.followers(@username).map do |follower|
      User.new(username: follower[:login], data: follower)
    end
  end

  def fetch_organizations
    client.all_organizations.map do |organization|
      Organization.new(id: organization[:node_id], data: organization)
    end
  end
end

class Repo < GitHub
  def initialize(data:)
    @data = data 
  end

  def assignees
    @assignees ||= fetch_assignees
  end

  def self.find_by_user(login)
    GitHub.new.client.repos(login).map do |repo|
      new(data: repo)
    end
  end

  private

  def fetch_assignees
    client.repository_assignees(id).map do |assignee|
      User.new(username: assignee[:login], data: assignee)
    end
  end

end

class Organization < GitHub
  def initialize(id:, data:)
    @id, @data = id, data
  end
end

user = User.by_username "maximus242"
puts "Test 1"
puts user.repos # Returns an array of Repo instances
puts "Test 2"
puts user.followers[0].organizations # Returns an array of Organization instances
puts "Test 3"
puts user.repos[0].assignees # Returns an array of User instances
