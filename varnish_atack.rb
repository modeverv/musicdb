#! /usr/bin/env ruby
# -*- coding:utf-8 -*-

load File.dirname(__FILE__) + '/models.rb'

require 'mechanize'
require 'json'
require 'uri'


def get(args)
  agent = Mechanize.new #省メモリ(but低速)を期待,メモリガベージコレクタが都度破棄してくれれば...
  agent.user_agent_alias = 'Windows IE 7'
  args[:p] ||=1
  args[:per]||= 100
  if(args[:useproxy])  
    agent.set_proxy('192.168.110.7', 3129)
  else
    agent.set_proxy('192.168.110.7', 3128)
    agent.read_timeout = 5
  end
  url = "#{args[:uri]}?p=#{args[:p]}&per=#{args[:per]}&qs=#{URI.encode(args[:qs])}"
  puts url
  agent.get url
  pj = JSON.parse agent.page.body
  if pj[0].next == "yes"
    return get({
                 useproxy:true,
                 uri:args[:uri],
                 p:args[:p] + 1,
                 per:args[:per],
                 qs:args[:qs],
               })
  else
    puts "end of search #{args[:qs]}"
  end
rescue => ex
  puts ex
  puts "end this qs attempt : #{args[:qs]}"
end

def main_genre(useproxy)
  #http://192.168.110.7/musicdb_dev/api/search_by_genre?p=2&per=5000&qs=VOCALOID
  args = {}
  if useproxy
    args[:uri] ||= "http://modeverv.dyndns.org/musicdb_dev/api/search_by_genre"
    args[:useproxy] = true
  else
    args[:uri] ||= "http://192.168.110.7/musicdb_dev/api/search_by_genre"
  end
  Genremodel.all.only(:name).to_a.sort.each do |g|
    args[:qs] = g.name
    get(args)    
  end
end
require 'pp'

def get_s(url,useproxy)
  agent = Mechanize.new #省メモリ(but低速)を期待,メモリガベージコレクタが都度破棄してくれれば...
  agent.user_agent_alias = 'Windows IE 7'
  agent.set_proxy('192.168.110.7', 3129)   if(useproxy)
  agent.read_timeout = 10
  agent.get url
rescue => ex
  pp ex
  case(ex)
  when Net::HTTP::Persistent::Error
    puts "do nothing"
  when Net::HTTPServiceUnavailable
    puts "sleep 2"
    sleep 2
  end
end

class M
  attr_accessor :artist
  def initialize(m)
    @artist = m
  end
end

@threads = []
def main_title
  Musicmodel.all.only(:artist).distinct(:artist).to_a.sort.each do |m|
    m = M.new(m)    
    puts "#{m.artist}"
=begin    
    @threads << Thread.new do 
      get_s("http://192.168.110.7/musicdb_dev/api/scrape/similar?artist=#{URI.escape m.artist}",false)
    end
    @threads << Thread.new do 
      get_s("http://192.168.110.7/musicdb_dev/api/scrape/bio?artist=#{URI.escape m.artist}",false)
    end
    @threads << Thread.new do 
      get_s("http://192.168.110.7/musicdb_dev/api/scrape/wikipedia?artist=#{URI.escape m.artist}",false)
    end
    @threads << Thread.new do 
      get_s("http://192.168.110.7/musicdb_dev/api/scrape/bio?artist=#{URI.escape m.artist}",false)
    end
    @threads << Thread.new do 
      get_s("http://192.168.110.7/musicdb_dev/api/scrape/wikipedia?artist=#{URI.escape m.artist}",false)
    end
=end

    
    @threads << Thread.new do 
      get_s("http://modeverv.dyndns.org/musicdb_dev/api/scrape/similar?artist=#{URI.escape m.artist}",true)
    end
    @threads << Thread.new do 
      get_s("http://modeverv.dyndns.org/musicdb_dev/api/scrape/bio?artist=#{URI.escape m.artist}",true)
    end
    @threads << Thread.new do 
      get_s("http://modeverv.dyndns.org/musicdb_dev/api/scrape/wikipedia?artist=#{URI.escape m.artist}",true)
    end
    @threads << Thread.new do 
      get_s("http://modeverv.dyndns.org/musicdb_dev/api/scrape/bio?artist=#{URI.escape m.artist}",true)
    end
    @threads << Thread.new do 
      get_s("http://modeverv.dyndns.org/musicdb_dev/api/scrape/wikipedia?artist=#{URI.escape m.artist}",true)
    end

    if(@threads.size > 200)
      @threads.each do |t|
        puts "joining ...."
        t.join
      end
      @threads = []
    end
  end
end
ts = []
ts << Thread.new do
  #  main_title
  main_genre(true)
end
ts << Thread.new do
#  main_genre(false)
end

ts << Thread.new do
  agent = Mechanize.new 
  agent.user_agent_alias = 'Windows IE 7'
  agent.set_proxy('192.168.110.7', 3128)
  url = "http://192.168.110.7/mediadb2/api/dirs?qs="
  agent.get url
  url = "http://192.168.110.7/mediadb2/"
  agent.get url
  
  agent = Mechanize.new 
  agent.user_agent_alias = 'Windows IE 7'
  agent.set_proxy('192.168.110.7', 3129)
  url = "http://modeverv.dyndns.org/mediadb2/api/dirs?qs="
  agent.get url
  url = "http://modeverv.dyndns.org/mediadb2/"
  agent.get url
end

ts.each do |t|
  t.join
end
# ruby /home/seijiro/sinatra/musicdb_dev/varnish_atack.rb 
