require 'rest-client'
require 'docker'
require 'discordrb'
require 'redis'
require 'json'

file = File.read('blob.json')
json = JSON.parse(file)
bot = Discordrb::Commands::CommandBot.new token: ENV['RBBY'], prefix: '~'

bot.ready do
  bot.game = json['games'].sample
  # Docker.url = 'tcp://192.168.1.130:5422'
  Docker::Container.all(all: true).each do |x|
    puts x.info.fetch('Image')
  end
end

bot.member_join do |event|
  event.server.default_channel.send_message event.user.display_name + ' has joined! :wave:'
end

bot.member_leave do |event|
  event.server.text_channels.select do |channel|
    channel.name == 'debug'
  end.first.send_message event.user.username + ' just left the server!'
end

bot.command :fortune do
  '``' + `fortune -s | cowsay` + '``'
end

bot.command :translate do |event|
  test = event.message.content.slice(11..event.message.content.length)
  RestClient.post 'http://api.funtranslations.com/translate/jive.json', text: test do |response, request, result|
    if result.code == '429'
      JSON.parse(result.body).dig('error', 'message')
    else
      JSON.parse(response.body).dig('contents', 'translated')
    end
  end
end

bot.command :catpic do
  RestClient.get('http://thecatapi.com/api/images/get?format=src&type=jpg').request.url
end

bot.command :catgif do
  RestClient.get('http://thecatapi.com/api/images/get?format=src&type=gif').request.url
end

bot.command :chucknorris do
  JSON.parse(RestClient.get('http://api.icndb.com/jokes/random?exclude=[explicit]'))['value']['joke']
end

bot.command :ghostbusters do
  '``' + `cowsay -f ghostbusters Who you Gonna Call` + '``'
end

bot.command :moo do
  '``' + `apt-get moo` + '``'
end

bot.command :rust do |event|
  if event.message.content.include?('time')
    redis = Redis.new(host: 'redis')
    redis.publish('RustCommands', event.message.content)
    redis.close
  end
  'done'
end

bot.command :minecraft do |event|
  puts 'recieved input for Minecraft'
  redis = Redis.new(host: 'redis')
  redis.publish('Minecraft', event.message.content)
  redis.close
end

bot.command :docker do |event|
  Docker::Container.all(all: true).each do |x|
    announce_message('debug', x.info.fetch('Image'), bot)
  end
  'Done!'
end

Thread.new do
  redis = Redis.new(host: 'redis')
  redis.subscribe('RustPlayers') do |on|
    puts 'subscribed to RustPlayers'
    on.message do |_channel, message|
      puts message
      announce_message 'rust-server', event.message.content, bot
    end
  end
end

Thread.new do
  redis = Redis.new(host: 'redis')
  redis.subscribe('newMinecraftPlayers') do |on|
    puts 'subscribed to newMinecraftPlayers'
    on.message do |_channel, message|
      puts message
      announce_message 'modded-minecraft-server', message, bot
    end
  end
end

Thread.new do
  redis = Redis.new(host: 'redis')
  redis.subscribe('MinecraftPlayers') do |on|
    puts 'subscribed to newMinecraftPlayers'
    on.message do |_channel, message|
      puts message
      announce_message 'debug', message, bot
    end
  end
end

# TODO: shouldn't have to pass reference to bot in the method
def announce_message(server, message, bot)
  # TODO: array.select is kinda like a foreach.. slow as balls
  bot.servers.dig(ENV['EGEEIO_SERVER'].to_i).text_channels.select do |channel|
    channel.name == server
  end.first.send_message(message)
end

bot.run
