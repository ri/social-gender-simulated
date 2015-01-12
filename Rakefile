require 'rake'
require 'twitter'
require 'json'
$VERBOSE=nil

client = Twitter::REST::Client.new do |config|
  config.consumer_key = "KIXDfc6CFZZQfFH4QZ6pA"
  config.consumer_secret = "VmXgzLHdtjNpRKGFiCh4MBcn0zzJQF4Ov40L8D8"
  config.access_token = "15574548-SpXzyUaLZznFEJGJZoVZEIxgvyNftmYDnQrZL4I14"
  config.access_token_secret = "UQtthHKiz77VGcLhcglmgwrcWp9cHn9aEUkUIGVXc"
end

namespace :data do
  desc "Seed data from Twitter"
  task :seed do
    friend_ids = client.friend_ids('bjeanes').to_a
    friends = client.users(friend_ids)
    data = []

    friends.each do |friend|
      puts "What gender is #{friend.name}, #{friend.screen_name}?"
      gender = case STDIN.gets.chomp
                 when /^m/i then 'male'
                 when /^f/i then 'female'
                 when /^b/i then 'brand'
                 else 'other'
               end

      puts "gender is #{gender}"

      friend_data = {
        :id =>        friend.id,
        :name =>      friend.name,
        :username =>  friend.screen_name,
        :image =>     friend.profile_image_url,
        :tweets =>    friend.statuses_count,
        :gender =>    gender,
        :protected => friend.protected
      }
      data << friend_data
    end

    File.open("public/data/bjeanes.json", "w") do |f|
      f.write(data.to_json)
    end
  end

  desc "Seed data from Twitter"
  task :redo_seed do
    friend_ids = client.friend_ids('bjeanes').to_a
    friends = client.users(friend_ids)
    old_data = JSON.parse(File.read("public/data/bjeanes.json"))
    data = []

    friends.each do |friend|
      existing_friend = old_data.detect {|f| f["username"] == friend.screen_name }

      if (existing_friend.nil?)
        puts "What gender is #{friend.name}?"
        gender = STDIN.gets.chomp
        puts "gender is #{gender}"
      else
        gender = existing_friend["gender"]
      end

      friend_data = {
        :id =>        friend.id,
        :name =>      friend.name,
        :username =>  friend.screen_name,
        :image =>     friend.profile_image_url,
        :tweets =>    friend.statuses_count,
        :gender =>    gender,
        :protected => friend.protected
      }
      data << friend_data
    end

    data.each do |friend|
      if friend_ids.include?(friend[:id])
        if friend[:protected] == true
          data.delete friend
        end
      end
    end

    File.open("public/data/bjeanes2.json", "w") do |f|
      f.write(data.to_json)
    end
  end

  desc "Get friends of friends"
  task :friends_of_friends do
    friends = JSON.parse(File.read("public/data/bjeanes2.json"))
    # done = JSON.parse(File.read("public/data/bjeanes_ff.json"))
    data = []
    p friends.length
    friends.each do |friend|
      # existing_friend = done.detect {|f| f["username"] == friend["username"] }
      existing_friend = nil
      if (existing_friend.nil?)
        begin
          friends_of_friends_ids = client.friend_ids(friend["id"]).to_a
          friend["friends"] = friends_of_friends_ids
          data << friend
          puts friend
        rescue Twitter::Error::TooManyRequests => error
          puts 'too many requests'
          puts 'sleeping'
          puts error
          sleep(15*60) # minutes * 60 seconds
          retry
        rescue Twitter::Error::NotFound
          puts "#{friend} not found"
        rescue Twitter::Error::ClientError
          sleep 5
          retry
        end
      end
    end

    File.open("public/data/bjeanes_ff.json", "w") do |f|
      f.write(data.to_json)
    end
  end


  desc "Equalise genders"
  task :equalise do
    friends = JSON.parse(File.read("public/data/bjeanes_ff.json"))
    data = equalise(friends)
    # womens = friends.select { |f| f["gender"] == 'female'}
    # mens = friends.select { |f| f["gender"] == 'male'}

    # while mens.length > womens.length
    #   random_guy = mens.sample
    #   mens.delete random_guy
    # end

    # data = womens + mens

    File.open("public/data/bjeanes_ff_equalised4.json", "w") do |f|
      f.write(data.to_json)
    end
  end

  desc "move from done to ff"
  task :move_done do 
    data = []
    current = JSON.parse(File.read("public/data/riblah_ff.json"))
    File.readlines("public/data/done.txt").each do |line|
      data << eval(line)
    end
    all_data = data + current
    File.open("public/data/riblah_ff.json", "w") do |f|
      f.write(all_data.to_json)
    end
  end

  desc "append file to another"
  task :append do 
    data = []
    file1 = JSON.parse(File.read("public/data/riblah_ff4.json"))
    file2 = JSON.parse(File.read("public/data/riblah_ff5.json"))
    puts file1.length
    puts file2.length
    result = file1.concat file2
    puts result.length
    File.open("public/data/riblah_ff6.json", "w") do |f|
      f.write(result.to_json)
    end
  end

  desc "generate nodes and links"
  task :gen_nodes_and_links do
    require 'set'

    friends = JSON.parse(File.read("public/data/bjeanes_ff_equalised4.json"))
    ri = {
      :id =>       15574548,
      :name =>     "Ri Liu",
      :username => "riblah",
      :image =>    "http://pbs.twimg.com/profile_images/458458978171645952/6VHFgMig_normal.jpeg",
      :tweets =>   6886,
      :gender =>   "female",
      :index =>    0
    }
    bo = {
      :id =>       13141092,
      :name =>     "Bo Jeanes",
      :username => "bjeanes",
      :image =>    "http://pbs.twimg.com/profile_images/502203461094477827/M1Ifm7Ld_normal.jpeg",
      :tweets =>   22022,
      :gender =>   "male",
      :index =>    0
    }
    data = gen_nodes_and_links(bo, friends)

    File.open("public/data/bjeanes_data_equalised4.json", "w") do |f|
      f.write(data.to_json)
    end
  end

  desc "generate stats for bo vs ri"
  task :stats do
    require 'array_stats'

    ri_source = JSON.parse(File.read("public/data/riblah_ff.json"))
    bo_source = JSON.parse(File.read("public/data/bjeanes_ff.json"))
    ri_stats = []
    bo_stats = []
    ri = {
      :id =>       15574548,
      :name =>     "Ri Liu",
      :username => "riblah",
      :image =>    "http://pbs.twimg.com/profile_images/458458978171645952/6VHFgMig_normal.jpeg",
      :tweets =>   6886,
      :gender =>   "female",
      :index =>    0
    }
   bo = {
      :id =>       13141092,
      :name =>     "Bo Jeanes",
      :username => "bjeanes",
      :image =>    "http://pbs.twimg.com/profile_images/502203461094477827/M1Ifm7Ld_normal.jpeg",
      :tweets =>   22022,
      :gender =>   "male",
      :index =>    0
    }
    100.times do 
      ri_data = gen_nodes_and_links(ri, equalise(ri_source))
      bo_data = gen_nodes_and_links(bo, equalise(bo_source))
      ri_stat = { :mtof => ri_data[:links].select { |l| l[:type] == "mtof" }.length,
             :mtom => ri_data[:links].select { |l| l[:type] == "mtom"}.length,
             :ftof => ri_data[:links].select { |l| l[:type] == "ftof"}.length,
             :ftom => ri_data[:links].select { |l| l[:type] == "ftom"}.length,
             :alltom => ri_data[:links].select { |l| l[:type] == "ftom" or l[:type] == "mtom"}.length,
             :alltof => ri_data[:links].select { |l| l[:type] == "ftof" or l[:type] == "mtof"}.length
           }
      bo_stat = { :mtof => bo_data[:links].select { |l| l[:type] == "mtof" }.length,
             :mtom => bo_data[:links].select { |l| l[:type] == "mtom"}.length,
             :ftof => bo_data[:links].select { |l| l[:type] == "ftof"}.length,
             :ftom => bo_data[:links].select { |l| l[:type] == "ftom"}.length,
             :alltom => bo_data[:links].select { |l| l[:type] == "ftom" or l[:type] == "mtom"}.length,
             :alltof => bo_data[:links].select { |l| l[:type] == "ftof" or l[:type] == "mtof"}.length
           }
      ri_stats.push ri_stat
      bo_stats.push bo_stat
    end
    data = {:bo => bo_stats, :ri => ri_stats}

    File.open("public/data/stats2.json", "w") do |f|
      f.write(data.to_json)
    end

  end

  def gen_nodes_and_links(user, friends)
    friendsParsed = friends.select { |f| f["gender"] == 'female' or f["gender"] == 'male' }
    links = Set.new
    nodes = Hash.new { |h, k| h[k] = {} }
    nodes[user[:id]] = user

    friendsParsed.each_with_index do |friend, i|
      add_friends(friend, nodes, links, i + 1)
      links << { source: user[:index], target: i + 1, type: "#{user[:gender][0]}to#{friend["gender"][0]}" }
    end

    friendsParsed.each_with_index do |friend, i|
      add_friends_of_friends(friend, nodes, links, i + 1)
    end

    { :nodes => nodes.values, :links => links.to_a }

  end

  def equalise(friends)
    womens = friends.select { |f| f["gender"] == 'female'}
    mens = friends.select { |f| f["gender"] == 'male'}

    while mens.length > womens.length
      random_guy = mens.sample
      mens.delete random_guy
    end

    womens + mens
  end

  def add_friends(friend, nodes, links, index)
    friend_obj = {
      :id =>       friend["id"],    
      :name =>     friend["name"],
      :username => friend["username"],
      :image =>    friend["image"],
      :tweets =>   friend["tweets"],
      :gender =>   friend["gender"],
      :index =>    index
    }
    nodes[friend_obj[:id]].merge!(friend_obj)
  end

  def add_friends_of_friends(friend, nodes, links, index)
    friend["friends"].each do |friend_id|
      # p friend_id
      # nodes[friend_id].merge! id: friend_id
      friend_of_friend = nodes.fetch(friend_id, nil)
      if friend_of_friend
        links << {
          :source => index,
          :target => friend_of_friend[:index],
          :type   => "#{friend['gender'][0]}to#{friend_of_friend[:gender][0]}"
        }
      end
    end
  end
end