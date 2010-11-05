#!/usr/bin/perl -w
#================================
#  license free BSD 
#  author  : sean chen @ funningboy@gmail.com
#  publish : 2010/11/04
#================================
use strict;
#use warnings;
use LWP::UserAgent;
use HTTP::Cookies;
use XML::Simple;
use Data::Dumper;
use threads;
use threads::shared;
use File::Path qw(make_path remove_tree);


my $UserName = 'xxx@gmail.com';
my $PassWord = 'xxx';

my $gl_bkup_set = './backup/';
my $gl_dwld_set = './download/';
 
my ($gl_up_set,$gl_tm_set,$gl_ph_set) = (-1,-1,-1);
my ($gl_dn_set,$gl_dy_set) = (-1,-1);

sub get_usage {
  print STDOUT "
    <USAGE>
       -[Uu] -[Tt] -[Pp] your_path 
       -[Dd] -[Yy] -[Pp] your_path
    <EX>
       -u -t 3600 -p /home/sean/prj/ss        #back up the project 'ss' && upload 2 google doc @ period of 3600s
                                              # 每3600s back up 一次,且上傳到 google doc server.

       -u -t 0    -p /home/sean/prj/ss        #back up the project 'ss' && upload 2 google doc right now
                                              # 立即備份,且上傳到 google doc server

       -d -y 2010/11/04 -p /home/sean/prj/ss  #download the project 'ss' by day 
                                              # 下載back up data by day
    ";
   die "\n";
}


unless($ARGV[0] && $#ARGV != 5){
   get_usage();
};

while(@ARGV){
  $_ = shift @ARGV;

    if( /-[Uu]$/ ){ $gl_up_set =1;           }
 elsif( /-[Tt]$/ ){ $gl_tm_set =shift @ARGV; }
 elsif( /-[Pp]$/ ){ $gl_ph_set =shift @ARGV; }
 elsif( /-[Dd]$/ ){ $gl_dn_set =1;           }
 elsif( /-[Yy]$/ ){ $gl_dy_set =shift @ARGV; }
 else{
   get_usage();
  }
} 

main();

sub gaDownLoadPath {
   my ($path) = (@_);
   if( !-e $path ){ make_path($path); }
return $path;
}

sub gaBackUpPath {
    my ($path) = (@_);
    if( !-e $path ){ make_path($path); }
return $path;
}

sub gaSysTime {
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
             $year += 1900;
             $mon  += 1;
           
           if($mon<10){  $mon="0".$mon;   }
           if($mday<10){ $mday="0".$mday; }

return $year.'_'.$mon.'_'.$mday.'_'.$hour.'_'.$min;
}

sub gaCmp2DownLoad {
   my ($i_path) = (@_);

}

sub gaBackUp2Cmp {
   my ($i_path,$bk_path,$time) = (@_);

   my @arr  = split("\/",$i_path);
   my $name = $bk_path.$time."_".$arr[$#arr].'_tar_gz.pdf';
   
   `tar -zcvf $name $i_path`;
   
return $name;
}

sub gaGetToken {
    my ($user,$pass) = (@_);

    my $ua = LWP::UserAgent->new;
         $ua->agent("MyApp/0.1");
         $ua->cookie_jar( {} );


    my $req = HTTP::Request->new(POST => 'https://www.google.com/accounts/ClientLogin');
       $req->content_type('application/x-www-form-urlencoded');
       $req->content("GData-Version=3.0&accountType=GOOGLE&Email=$user&Passwd=$pass&service=writely&source=companyName-applicationName-versionID");

    my $res = $ua->request($req);

    my $token;
    
    if ($res->is_success) {
        if ($res->content =~ m/(?<=Auth=).*/im) {
            $token = $&;
        }
    }
    else {
        return 'error: '. $res->status_line;
        die;
    }

    return $token;
}

sub gaUserID{
    my ($usrnm) = (@_);
    
    if( $usrnm =~ m/^(\w+)\@gmail\.com/ ){
    	  $usrnm = $1;
    	}
  return $usrnm;  	
}


sub gaUpLoadFile { 
  my ($auth,$file) = (@_);

  my $size = -s $file;
  my $data = ""; { local $/; open(FILE,"<$file") || die $!;
  binmode(FILE); $data = <FILE>; } close(FILE);
  
  my $url = 'https://docs.google.com/feeds/default/private/full';
  my $req = HTTP::Request->new(POST => "$url");
  
  $req->header(Authorization => "GoogleLogin auth=$auth",
               "GData-Version" => "3.0",
               "Slug" => $file);
                
  $req->content_length($size);
  $req->content_type("application/pdf");

  $req->content($data);
  
  my $ua = LWP::UserAgent->new;
  my $res= $ua->request($req);
           $ua->cookie_jar( {} );

  if( $res->is_success){ print "upload file @ $file pass...\n";   }
  else{                  print "upload file @ $file error...\n";
                         print $res->status_line;         }
}

sub gaAllList{
    my ($token,$userID) = (@_);
    
    my $ua = LWP::UserAgent->new;
       $ua->agent("MyApp/0.1");
       $ua->cookie_jar( {} );

    my @headers = ("Authorization" => "GoogleLogin Auth=$token",
                   "GData-Version" => "3.0" );

    my $url = 'https://docs.google.com/feeds/default/private/full';
    my $res = $ua->get($url, @headers);
    
    my %list =();
    if ($res->is_success) {
        my ($content, $e, $a);
            $content = $res->content;
        
        my $xml = new XML::Simple(KeyAttr=>[]);
        my $tree = $xml->XMLin($content);
        #print Dumper($tree);
       
        my $id =0; 
        foreach $e ($tree->{entry}){
          foreach $a (@{$e}){
               $list{$id}{TITLE} = $a->{'title'};
               $list{$id}{SRC}   = $a->{'content'}->{'src'};
               $id++;
             }
          }
    } else {
        return "error: ". $res->status_line;
        die;
    }

  return \%list;
}


sub gaDownLoadFile{
    my ($token,$userID,$bk_path,$dw_path,$list) = (@_);
    if( ! keys %{$list} ){ die printf("the server @ google doc is empty\n"); }
    
    my $ua = LWP::UserAgent->new;
       $ua->agent("MyApp/0.1");
       $ua->cookie_jar( {} );

    my @headers = ("Authorization" => "GoogleLogin Auth=$token",
                   "GData-Version" => "3.0" );

     my %list = %{$list};
  foreach my $id ( keys %list ){
     my $title= $list{$id}{TITLE};
     my $url  = $list{$id}{SRC};

     my $res  = $ua->get($url, @headers);

        $title =~ s/$bk_path//g;

     my $path  = $dw_path.$title;
     open STDOUT ,">$path" or die "open $path error\n"; 

    if ($res->is_success) {
        print STDOUT  $res->content;
    } else {
        return 'error: '. $res->status_line;
        die;
    }
    close(STDOUT);
  }
}

sub gaIsExist {
   my ($list,$i_day,$i_path) = (@_);
   if( ! keys %{$list} ){ die printf("the server @ google doc is empty\n"); }
 
   my ($YY,$MM,$DD) = split("\/",$i_day); 
   my @arr_p        = split("\/",$i_path);
   my $reg_exp      = $YY.'_'.$MM.'_'.$DD.'_'.'[0-9]*_[0-9]*_'.$arr_p[$#arr_p].'_tar_gz.pdf';
   my %rst =();

   my $id =0;
   my %list = %{$list};
   foreach my $t ( keys %list ){
     if( $list{$t}{TITLE} =~ m/$reg_exp/ ){
         $rst{$id}{TITLE} = $list{$t}{TITLE};
         $rst{$id}{SRC}   = $list{$t}{SRC};
         $id++;
    }
  } 

return \%rst;
}


sub get_upload {
              gaBackUpPath($gl_bkup_set);
my $time    = gaSysTime();
my $file    = gaBackUp2Cmp($gl_ph_set,$gl_bkup_set,$time);

my $token   = gaGetToken($UserName,$PassWord);
my $usrID   = gaUserID($UserName);
              gaUpLoadFile($token,$file);
#             gaclose();
}

sub get_download {
              gaDownLoadPath($gl_dwld_set);

my $token   = gaGetToken($UserName,$PassWord);
my $usrID   = gaUserID($UserName);
my $all_list= gaAllList($token,$usrID);
my $is_list = gaIsExist($all_list,$gl_dy_set,$gl_ph_set);
              gaDownLoadFile($token,$usrID,$gl_bkup_set,$gl_dwld_set,$is_list);
#             gaClose();
}

sub main {
    my $time = int($gl_tm_set);
    if($gl_up_set eq '1' && $time >= 60){
       for(;;){
          my $thr_0 = threads->create(\&get_upload);
             $thr_0->join();
             sleep  $time;
          }

   } elsif($gl_up_set eq '1' && $time ==0 ){
          my $thr_1 = threads->create(\&get_upload);
             $thr_1->join();

   } elsif($gl_dn_set eq '1'){
          my $thr_2 = threads->create(\&get_download);
             $thr_2->join();
   } else {
      get_usage();
   } 
}

