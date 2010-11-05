#!/usr/bin/perl -w
use strict;
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;


my $UserName = 'xxxx.gmail.com';
my $PassWord = 'xxxxx';

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
    $req->content("accountType=GOOGLE&Email=$user&Passwd=$pass&service=finance&source=companyName-applicationName-versionID");

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

# authenticate with the API to receive token
my $token = &gaGetToken($UserName,$PassWord);

# this sub will return an array of all your ga accounts
# you need to pass your token to it
sub gaAccounts {
    # the token you passed to this sub
    my $token = $_[0];

    # create user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");

    # add authorization to headers
    my @headers = ("Authorization" => "GoogleLogin Auth=$token",
                   "GData"         => "v=2");

    # request the accounts feed
    my $res = $ua->get('http://finance.google.com/finance/feeds/default/portfolios/', @headers);

    # define accounts array
    my @accounts;

    # if the request was successful...
    if ($res->is_success) {
        # declare variables
        my ($content, $e);

        # this is the xml it returns
        $content = $res->content;

        # create a xml object for the response
        my $xml = new XML::Simple(KeyAttr=>[]);
        my $tree = $xml->XMLin($content);

        # iterate through each entry
        my $x = 0;
        
        #print Dumper($tree);
        $e = $tree->{entry};
        #foreach $e (@{$tree->{entry}})
        #{
            # add the account to the array
            $accounts[$x][0] = $e->{title}->{content};
            $accounts[$x][1] = $e->{'id'};
            $x++
        #}

    } else {
        # return the error if there was a problem
        return "error: ". $res->status_line;
        die;
    }

    # return the array of accounts
    return @accounts;
}

gaAccounts($token);


sub gaAccounts2 {
    # the token you passed to this sub
    my $token = $_[0];

    # create user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");

    # add authorization to headers
    my @headers = ("Authorization" => "GoogleLogin Auth=$token",
                   "GData"         => "v=2");

    # request the accounts feed
    my $res = $ua->get('http://finance.google.com/finance/feeds/default/portfolios/1/positions/TPE:2330/transactions/1', @headers);

    # define accounts array
    my @accounts;

    # if the request was successful...
    if ($res->is_success) {
        # declare variables
        my ($content, $e);

        # this is the xml it returns
        $content = $res->content;
        
        # create a xml object for the response
        my $xml = new XML::Simple(KeyAttr=>[]);
        my $tree = $xml->XMLin($content);

        # iterate through each entry
        my $x = 0;
        
        print Dumper($tree);
  
    } else {
        # return the error if there was a problem
        return "error: ". $res->status_line;
        die;
    }

    # return the array of accounts
    return @accounts;
}

gaAccounts2($token);