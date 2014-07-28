#!/usr/bin/env ruby
# encoding: utf-8

($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem
require_relative "bundle/bundler/setup"
require "alfred"

require 'codebase_api'

def config_codebase_api

  # API credentials
  CodebaseApi.account_user = ENV["CB_ACCOUNT_USER"]
  CodebaseApi.api_key = ENV["CB_API_KEY"]
  
end

def get_all_tickets
  
  CodebaseApi::Ticket.all(ENV["CB_DEFAULT_PROJECT"])
  
end

def search_tickets( query )
  
  CodebaseApi::Ticket.search(ENV["CB_DEFAULT_PROJECT"], query)
  
end


def generate_feedback(alfred, tickets, query)

  feedback = alfred.feedback
  
  base_url = "https://#{ENV["CB_ACCOUNT_USER"].split('/').first}.codebasehq.com/projects/#{ENV["CB_DEFAULT_PROJECT"]}/tickets"
  
  i = 0
  
  tickets.each do |t|
    feedback.add_item({
      :title              => t['ticket']['summary'],
      :subtitle           => "Ticket #{t['ticket']['ticket_id']} | #{t['ticket']['status']['name']}#{' | ' + t['ticket']['milestone']['name'] if t['ticket']['milestone']}" ,
      :arg                => URI.escape("#{base_url}/#{t['ticket']['ticket_id']}"),
      :autocomplete       => t['ticket']['summary'],
      :icon               => {:type => "default", :name => "icons/#{t["ticket"]["ticket_type"].downcase}.png"},
    })

    i += 1
    if i == 2
      feedback.add_item({
        :title    => "Search tickets for '#{query}'",
        :subtitle => "Open browser for more results.",
        :arg      => URI.escape("#{base_url}?query=#{query}"),
        :icon     => {:type => "default", :name => "icon.png"},
      })
    end

  end

  puts feedback.to_xml
end

if __FILE__ == $PROGRAM_NAME
  if ['/h', '/help'].include? ARGV[0]
    exit 0
  end

  Alfred.with_friendly_error do |alfred|
    alfred.with_rescue_feedback = true
    query = ARGV.join("+").strip.sub(' ','+')
    
    config_codebase_api
    
    if( query.empty? )
      tickets = get_all_tickets
    else
      tickets = search_tickets(query)
    end

    generate_feedback(alfred, tickets, query) if tickets
  end
end


