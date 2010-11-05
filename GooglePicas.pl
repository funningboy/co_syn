#!/usr/bin/perl -w
use strict;
use warnings;
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;


my $UserName = 'xxxx@gmail.com';
my $PassWord = 'xxxx';

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
    $req->content("accountType=GOOGLE&Email=$user&Passwd=$pass&service=lh2&source=companyName-applicationName-versionID");

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

sub gaUserID{
    my $usrnm = $_[0];
    
    if( $usrnm =~ m/^(\w+)\@gmail\.com/ ){
    	  $usrnm = $1;
    	}
  return $usrnm;  	
}

sub gaAlbumID {
    # the token you passed to this sub
    my $token  = $_[0];
    my $userID = $_[1];
    
    # create user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");

    # add authorization to headers
    my @headers = ("Authorization" => "GoogleLogin Auth=$token",
                   "GData"         => "v=2");

    # request the accounts feed
    my $res = $ua->get("http://picasaweb.google.com/data/feed/api/user/$userID", @headers);
    
    my @AlbumID; 
    
    # if the request was successful...
    if ($res->is_success) {
        # declare variables
        my ($content, $e, $a);
    
        # this is the xml it returns
        $content = $res->content;
        
        my $x=0;
        
        # create a xml object for the response
        my $xml = new XML::Simple(KeyAttr=>[]);
        my $tree = $xml->XMLin($content);
        
        #print Dumper($tree);
        
        foreach $e ($tree->{entry}){
        	foreach $a (@{$e}){
            if($a->{'id'} =~m/^.*albumid\/(\w+)/){
               $AlbumID[$x] = $1; 
               $x++;
             }
          }
        }
    } else {
        # return the error if there was a problem
        return "error: ". $res->status_line;
        die;
    }

    return @AlbumID;
}

sub gaPhotoID {
	    # the token you passed to this sub
    my $token   = $_[0];
    my $userID  = $_[1];
    my $albumID = $_[2];
    
    # create user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");

    # add authorization to headers
    my @headers = ("Authorization" => "GoogleLogin Auth=$token",
                   "GData"         => "v=2");

    # request the accounts feed
    my $res = $ua->get("http://picasaweb.google.com/data/feed/api/user/$userID/albumid/$albumID", @headers);
    
    my @PhotoID; 
    
    # if the request was successful...
    if ($res->is_success) {
        # declare variables
        my ($content, $e, $a);
    
        # this is the xml it returns
        $content = $res->content;
        
        my $x=0;
        
        # create a xml object for the response
        my $xml = new XML::Simple(KeyAttr=>[]);
        my $tree = $xml->XMLin($content);
        
        #print Dumper($tree);

        foreach $e ($tree->{entry}){
        	foreach $a (@{$e}){
               $PhotoID[0][$x] = $a->{'gphoto:id'}; 
               $PhotoID[1][$x] = $a->{'media:group'}->{'media:content'}->{'url'};
               $x++;
          }
        }
    } else {
        # return the error if there was a problem
        return "error: ". $res->status_line;
        die;
    }

    return @PhotoID;
}


my $token   = &gaGetToken($UserName,$PassWord);
my $usrID   = &gaUserID($UserName);
my @AlbumID = &gaAlbumID($token,$usrID);

my ($AbID,$PhID,$PhID2);
my @PhotoID;

print "UserID :: ".$usrID."\n";

foreach $AbID (@AlbumID){
print "   AlbumID :: ".$AbID."\n";
   	@PhotoID = &gaPhotoID($token,$usrID,$AbID);
   	foreach $PhID (@{$PhotoID[0]}){
   	    print "     PhotoID :: ".$PhID."\n";
    }
    foreach $PhID2 (@{$PhotoID[1]}){
        print "     URL     :: ".$PhID2."\n";	
    }
}
exit;


