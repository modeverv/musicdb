# -*- coding:utf-8 -*-
require 'rubygems'
require 'sinatra'

#require '/home/seijiro/sinatra/mediadb/main.rb'
require File.dirname(__FILE__)+'/main.rb'

use Rack::ETag
use Rack::Deflater

use Rack::Mongoid::Middleware::IdentityMap

run Sinatra::Application
