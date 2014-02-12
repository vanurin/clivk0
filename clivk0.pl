#!/usr/bin/perl

####### CliVk0 is a textual interface to social network Vk.com #######

use strict;
use warnings;
use URI::Escape;

#### Hash of methods
my %method_refs = ("audio.search" => \&audio_search,
       		   "messages.send" => \&messages_send,
   		   "messages.get" => \&messages_get);
#print "method_refs:\n".{map {$_ => $method_refs{$_}} keys %method_refs};


#### Authorization
## Read from auth.conf and auth.token, try this token, in case of failure get a new one
# Read from auth.conf
# Dangerous!! Please make a defence from additional lines in file, etc.!
open FH, "auth.conf" or die $!;
# Reading header of the file
<FH>;		#what about repetitive operator?
<FH>;		#some troubles with it.
my @auth_read;
(push @auth_read, <FH>) for (1..7);
my ($USER_ID,$APP_ID,$PERMISSIONS,$REDIRECT_URI,$DISPLAY,$API_VERSION,$RESPONSE_TYPE) = map {tr/\'//d; (split("[=;]", $_))[1];} @auth_read;
close FH;
#my $APP_ID = 4037393; 					#id of CliVk0
#my $PERMISSIONS = 4096; 				#extended messages processing
#my $REDIRECT_URI = 'https://oauth.vk.com/blank.html'; 	#standard filling for Standalone app
#my $DISPLAY = 'mobile';					#view of request of authorization
#my $API_VERSION = '5.5';				#version of requestion vk.com API
#my $RESPONSE_TYPE = 'token'; 				#standard for Standalone app ('code' for server app)

# Read old access token from auth.token
open FH, "<auth.token" or die $!;
my $access_token = <FH>;
my $param_postfix = "&v=$API_VERSION&access_token=$access_token";
close FH;

#####
# trying simple request to determine if current access token is valid
my $test_request_res = request("messages.get", "1", "0", "1");
#print $test_request_res;
#####

if ($test_request_res =~ m/error/) {	#if not valid --- ask for a new token and write it to auth.token.
	my $auth_request = "https://oauth.vk.com/authorize?client_id=$APP_ID&scope=$PERMISSIONS&redirect_uri=$REDIRECT_URI&display=$DISPLAY&v=$API_VERSION&response_type=$RESPONSE_TYPE";
	system("open", "-a", "Safari");
	system("osascript", "-e", "tell application \"Safari\" to open location \"$auth_request\"");
	#### Reading access_token from STDIN
	print "\nEnter access_token, please:\n";
	$access_token = (split /=|&/, <STDIN>)[1];
	#### Saving token in auth.token
	open FH, ">auth.token" or die $!;
	print FH $access_token;
	close FH;
}

###### Request from script arguments
print request(@ARGV);
### Request subroutine
sub request{
	my $request_name = shift;
	my @params =  map {uri_escape $_} @_;
	my $request = &{$method_refs{$request_name}}(@params);
	open PIPE, "curl \'$request\' |" or die $!;
	my $json_rslt = <PIPE>;
	print $json_rslt, "\n";
	return $json_rslt;
}


#### Get Audio by id

sub audio_getById {
	my $method_name = "audio.getById";
	my $parameters = shift;
	#### TODO
}

#### Search Audio

sub audio_search {
	my $method_name = "audio.search";
	my $q = shift;			#text of request
	my $count = shift;		#number of returned objects
#	print '$count = '.$count."\n";
	my $parameters = "q=$q&sort=2&count=$count";
	return "https://api.vk.com/method/$method_name?$parameters$param_postfix"; 
}

#### Get messages

sub messages_get {
	my $method_name = "messages.get";
	my $out = shift;
	my $offset = shift;
	my $count = shift;
	return "https://api.vk.com/method/$method_name?out=$out&offset=$offset&count=$count$param_postfix";	
}
##### Send Message
# now first arg is target id, second arg is message text
sub messages_send {
	my $method_name = "messages.send";
	#### TODO domain
	my $target_user_id = shift;					#target user, int
	#my $domain							#short user addres, string
	#my $chat_id							#target chat id, positive number
	my $target_user_ids = "";					#target user ids in case of new chat creation, numners devided by commas
	my $message = shift;							#text of personal message obligatory unless attachment is not empty, string
	my $title;							#message title, string
	# $type 							#'0' — ordinary message, '1' — message from chat. (default — 0), int
	# $guid					#unique id to prevent sending same messages again, int
	# $latlatitude 				#latitude to geopositioning, floating point
	# $longlongitude 			#longitude to geopositioning, floating point
	# $attachment				#attachments, see more at https://vk.com/dev/messages.send
	# $forward_messages			#ids of forwarding messages, comma delimeted

#	$message = uri_escape $message;
	my $parameters = "user_id=$target_user_id&message=$message";
	return "https://api.vk.com/method/$method_name?$parameters$param_postfix";
}
