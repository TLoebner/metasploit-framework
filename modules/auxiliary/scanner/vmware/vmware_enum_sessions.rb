##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'
require 'rex/proto/ntlm/message'


class Metasploit3 < Msf::Auxiliary
	include Msf::Exploit::Remote::VIMSoap
	include Msf::Exploit::Remote::HttpClient
	include Msf::Auxiliary::Report
	include Msf::Auxiliary::Scanner

	def initialize
		super(
			'Name'           => 'VMWare Enumerate Active Sessions',
			'Version'        => '$Revision$',
			'Description'    => %Q{
							This module will log into the Web API of VMWare and try to enumerate
							all the login sessions.},
			'Author'         => ['TheLightCosine <thelightcosine[at]metasploit.com>'],
			'References'     =>
				[
					[ 'CVE', '1999-0502'] # Weak password
				],
			'License'        => MSF_LICENSE
		)

		register_options(
			[
				Opt::RPORT(443),
				OptString.new('USERNAME', [ true, "The username to Authenticate with.", 'root' ]),
				OptString.new('PASSWORD', [ true, "The password to Authenticate with.", 'password' ])
			], self.class)
	end


	def run_host(ip)
		if vim_do_login(datastore['USERNAME'], datastore['PASSWORD']) == :success
			vim_sessions = vim_get_session_list
			case vim_sessions
			when :noresponse
				print_error "Connection Error - Recieved No Reply from #{ip}"
			when :error
				print_error "An error has occured"
			when :expired
				print_error "The Session is no longer Authenticated"
			else
				output = ''
				vim_sessions.each do |vsession| 
					tmp_line = "Name: #{vsession['fullName']} \n\t"
					tmp_line << "Active: #{vim_session_is_active(vsession['key'],vsession['userName'])} \n\t"
					tmp_line << "Username: #{vsession['userName']}\n\t"
					tmp_line << "Session Key: #{vsession['key']}\n\t"
					tmp_line << "Locale: #{vsession['locale']}\n\t"
					tmp_line << "Login Time: #{vsession['loginTime']}\n\t"
					tmp_line << "Last Active Time: #{vsession['lastActiveTime']}\n\n"
					print_good tmp_line
					output << tmp_line
				end
				unless output.empty?
					store_loot("VMWare Active Login Sessions", "text/plain", datastore['RHOST'], output, "vmware_sessions.txt", "Login Sessions for VMware")
				end
			end
		else
			print_error "Login Failure on #{ip}"
			return
		end
	end




end

