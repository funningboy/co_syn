#!/usr/bin/perl -w
use strict;
use warnings;
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;


my $UserName = 'xxxx@gmail.com';
my $PassWord = 'xxxx';

# this sub will return the token you need to authenticate api requests
# you need to pass your ga login and password to it
sub gaGetToken {
    # arguments passed to this function
    my $user = $_[0];
    my $pass = $_[1];

    # create user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");

    # Create a request
    my $req = HTTP::Request->new(POST => 'https://www.google.com/accounts/ClientLogin');
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("accountType=GOOGLE&Email=$user&Passwd=$pass&service=blogger&source=companyName-applicationName-versionID");

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # declare variable
    my $token;
    
    # Check the outcome of the response
    if ($res->is_success) {
        # look at the result
        if ($res->content =~ m/(?<=Auth=).*/im) {
            # store token so it can be used in subsequent requests
            $token = $&;
        }
    }
    else {
        # return the error if there was a problem
        return "error: ". $res->status_line;
        die;
    }

    # return the token
    return $token;
}

# this sub will return an array of all your ga accounts
# you need to pass your token to it
sub gaBlogID {
    # the token you passed to this sub
    my $token = $_[0];

    # create user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");

    # add authorization to headers
    my @headers = ("Authorization" => "GoogleLogin Auth=$token",
                   "GData"         => "v=2");

    # request the accounts feed
    my $res = $ua->get('http://www.blogger.com/feeds/default/blogs', @headers);
    
    my $BlogID; 
    
    # if the request was successful...
    if ($res->is_success) {
        # declare variables
        my ($content, $e);

     
        # this is the xml it returns
        $content = $res->content;

        # create a xml object for the response
        my $xml = new XML::Simple(KeyAttr=>[]);
        my $tree = $xml->XMLin($content);
        
        if($tree->{entry}->{'id'} =~m/blog\-(\w+)/){
           $BlogID = $1; 
          }
    } else {
        # return the error if there was a problem
        return "error: ". $res->status_line;
        die;
    }

    return $BlogID;
}

sub gaPostID {
    # the token you passed to this sub
    my $token  = $_[0];
    my $BlogID = $_[1];
    
    # create user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");

    # add authorization to headers
    my @headers = ("Authorization" => "GoogleLogin Auth=$token",
                   "GData"         => "v=2");

    # request the accounts feed
    my $res = $ua->get('http://www.blogger.com/feeds/1440181758261155873/posts/default', @headers);
    
    my @PostID; 
    
    # if the request was successful...
    if ($res->is_success) {
        # declare variables
        my ($content, $e, $a, $h);

     
        # this is the xml it returns
        $content = $res->content;
        
        # create a xml object for the response
        my $xml = new XML::Simple(KeyAttr=>[]);
        my $tree = $xml->XMLin($content);
        
        my $x = 0;
        
        foreach $e (@{$tree->{entry}})
        {
            foreach $a (@{$e->{link}}){
            	 if( $a->{href} =~ m/^.*default\/(\w+)$/){  
            	 	$PostID[$x] = $1;
            	 	$x++;	
            	}
            }
        }

        
    } else {
        # return the error if there was a problem
        return "error: ". $res->status_line;
        die;
    }
    
    return @PostID;
}

my $token  = &gaGetToken($UserName,$PassWord);

my $BlogID = &gaBlogID($token);

my @PostID = &gaPostID($token,$BlogID);

my $PtID;

print "BlogID" ."->". "PtID" . "\n";	
foreach $PtID (@PostID){
   print $BlogID ."->". $PtID . "\n";	
}