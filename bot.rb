require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'twss'
require 'cinch'
require 'json'

TWSS.threshold = 9.0

$password = gets
puts 'got password'

$config = JSON.load(open('config.json'))

bot = Cinch::Bot.new do
	configure do |c|
		c.server = $config['server']
		c.nick = '_internsbot'
		c.user = $config['user']
		c.verbose = true
		c.channels = ['#Interns']
		c.port = $config['port']
		c.password = $password.chomp
		c.ssl.use = true
		c.ssl.verify = false 
		@autovoice = true
	end

	helpers do
		
		def get_gif()
			Nokogiri::HTML(open('http://www.gifbin.com/random')).at('img#gif').attr('src')
		end

		def urban_dict(query)
		      url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(query)}"
		      CGI.unescape_html Nokogiri::HTML(open(url)).at("div.definition").text.gsub(/\s+/, ' ') rescue nil
	    	end

		def google_images(query)
			json = JSON.parse(open('http://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=8&q='+CGI.escape(query)).read)
			images = json['responseData']['results']
			images[rand(images.length)]['unescapedUrl']
		end

	end

	on :join do |m|
		unless m.user.nick == bot.nick
			m.channel.voice(m.user) if @autovoice
		end
	end

	on :channel, /^!autovoice (on|off)$/ do |m, option|
		@autovoice = option == "on"
		m.reply "Autovoice is now #{@autovoice ? 'enabled' : 'disabled'}"
	end

	on :message, /^.gifme/ do |m|
		if (rand(3) == 0) 
			m.reply('too many gifs...')
		else
			m.reply(get_gif() || "Err getting gif", true)
		end
	end

	on :message, /(hipster|clown|scumbag|rohan|jason)( me)? (.*)/i do |m, type, msg, arg|
		if arg.match /^https?:\/\//i
			imgsrc = arg
		else
			imgsrc = google_images(arg)	
		end
		m.reply("http://faceup.me/img.jpg?overlay=#{type}&src=#{imgsrc}")
	end
 
	on :message, /^.urban (.+)/ do |m, term|
		m.reply(urban_dict(term) || "No results found", true)
	end
 
	on :message, /bot.*stop/ do |m|
		reply = Format(:underline, 'I will %s %s%s' % [Format(:bold, 'never'), Format(:red, 'stop'), Format(:blue, '!')])
		m.reply(reply)
	end

	on :message do |m|
		if TWSS(m.message)
			m.reply('that\'s what she said')
		end
	end

	on :message, /is (my|it) (.+)$/ do |m, text|
		m.reply('%s, it isn\'t.' % [Format(:bold, 'no')])
	end

	on :message, /is (.*) (down|up)/ do |m, service, type|
		m.reply('check for yoself.')		
	end

	on :message, /did i break (.*)/i do |m, service|
		m.reply('um, yes. you broke ' + service, true)
		m.reply('http://25.media.tumblr.com/a4d6c7d8d67f3133569a6993d05bdb87/tumblr_mog3us0CqJ1suqlmoo1_400.gif') 
	end

	on :message, /^\.boom$/ do |m|

	end

	on :message, /^.image (.+)$/i do |m, search|
		m.reply(google_images(search), true)
	end

	on :message, /^.moustache (.+)$/i do |m, search|
		type = rand(3)
		img = google_images(search)
		m.reply(img)
		m.reply("http://mustachify.me/#{type}?src=" + img, true)
	end

end

bot.start
