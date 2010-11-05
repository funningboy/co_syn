
use strict;
use WWW::Mechanize;
use HTTP::Cookies;
use HTML::Parse;
use Data::Dumper;
use XML::Simple;
use HTML::Parser;
use utf8;


my %FaceBookAPPHs;
my %FarmAPPHs;


Login2FaceBook();
#print Dumper(\%FaceBookAPPHs);
LoadFarmLand();
#print Dumper(\%FarmAPPHs);
LoadItems();

LoadFarmLandInf();

sub Login2FaceBook {
my $url   = 'http://www.facebook.com';
my $email = 'xxxx@gmail.com';
my $pass  = 'xxxx';
my $appurl = 'http://apps.facebook.com/farmgame_tw';


my $mech = WWW::Mechanize->new(   agent => 'Windows IE 6',
                                  env_proxy => 1,
                                  keep_alive => 1,
                                  timeout => 60,
);

$mech->cookie_jar(HTTP::Cookies->new());

$mech->get($url);

$mech->forms('menubar_login');
$mech->field(email => $email);
$mech->field(pass  => $pass);
$mech->click();
my $facebook_content = $mech->content();


#login in
if($mech->success()){
	 print  "Login Ok ...\n";
	} else {
   print "Login Fail ...\n".$mech->status(); die;
 }



#2 the FarmLand
$mech->get($appurl);
if($mech->success()){
  print "2 FarmLand ok ...\n";
} else {
	print "2 FarmLand Fail ...\n".$mech->status(); die; 
	}
my $app_content = $mech->content();
#print $app_content;



#Parse Key Word
my $LoadFarmUrl;
my ($act                       ,$firstPlay            ,$fb_sig_in_iframe     ,$fb_sig_iframe_key            ,$fb_sig_locale);
my ($fb_sig_in_new_facebook    ,$fb_sig_time          ,$fb_sig_added         ,$fb_sig_profile_update_time   ,$fb_sig_expires);
my ($fb_sig_user               ,$fb_sig_session_key   ,$fb_sig_ss            ,$fb_sig_cookie_sig            ,$fb_sig_ext_perms);
my ($fb_sig_api_key            ,$fb_sig_app_id        ,$fb_sig);


if($app_content =~ m/\<iframe src=\"http:\/\/fbfarmtw.elex-tech.us\/myfarm\/facebook_tw\/index.php\?(\S+)\" / ){
	   $LoadFarmUrl = $1;
	   #print $1;
	   
	   my @MyArr = split("\;",$LoadFarmUrl);
	   
	   foreach my $a (@MyArr){
	   	       $a =~ s/\&amp//;
	   	    if($a =~ m/act=(\S+)/                       ){ $act                   =$1; }
	   	 elsif($a =~ m/firstPlay=(\S+)/                 ){ $firstPlay             =$1; }
	   	 elsif($a =~ m/fb_sig_in_iframe=(\S+)/          ){ $fb_sig_in_iframe      =$1; }
	     elsif($a =~ m/fb_sig_iframe_key=(\S+)/         ){ $fb_sig_iframe_key     =$1; }
	     elsif($a =~ m/fb_sig_locale=(\S+)/             ){ $fb_sig_locale         =$1; } # 5
       elsif($a =~ m/fb_sig_in_new_facebook=(\S+)/    ){ $fb_sig_in_new_facebook=$1; }
       elsif($a =~ m/fb_sig_time=(\S+)/               ){ $fb_sig_time           =$1; }
       elsif($a =~ m/fb_sig_added=(\S+)/              ){ $fb_sig_added          =$1; }
       elsif($a =~ m/fb_sig_profile_update_time=(\S+)/){ $fb_sig_profile_update_time =$1;}
       elsif($a =~ m/fb_sig_expires=(\S+)/            ){ $fb_sig_expires        =$1; }     #5     
       elsif($a =~ m/fb_sig_user=(\S+)/               ){ $fb_sig_user           = $1;}
       elsif($a =~ m/fb_sig_session_key=(\S+)/        ){ $fb_sig_session_key    =$1; }
       elsif($a =~ m/fb_sig_ss=(\S+)/                 ){ $fb_sig_ss             =$1; }
       elsif($a =~ m/fb_sig_cookie_sig=(\S+)/         ){ $fb_sig_cookie_sig     =$1; }
       elsif($a =~ m/fb_sig_ext_perms=(\S+)/          ){ $fb_sig_ext_perms      =$1; }  #5
       elsif($a =~ m/fb_sig_api_key=(\S+)/            ){ $fb_sig_api_key        =$1; }
       elsif($a =~ m/fb_sig_app_id=(\S+)/             ){ $fb_sig_app_id         =$1; }
       elsif($a =~ m/fb_sig=(\S+)/                    ){ $fb_sig                =$1; }
       
    }
      %FaceBookAPPHs = (
      	"act"                        => $act,
      	"firstPlay"                  => $firstPlay,
      	"fb_sig_in_iframe"           => $fb_sig_in_iframe,
      	"fb_sig_iframe_key"          => $fb_sig_iframe_key,
      	"fb_sig_locale"              => $fb_sig_locale,
      	"fb_sig_in_new_facebook"     => $fb_sig_in_new_facebook,
      	"fb_sig_time"                => $fb_sig_time,
      	"fb_sig_added"               => $fb_sig_added,
      	"fb_sig_profile_update_time" => $fb_sig_profile_update_time,
      	"fb_sig_expires"             => $fb_sig_expires,
      	"fb_sig_user"                => $fb_sig_user,
      	"fb_sig_session_key"         => $fb_sig_session_key,
      	"fb_sig_ss"                  => $fb_sig_ss,
      	"fb_sig_cookie_sig"          => $fb_sig_cookie_sig,
      	"fb_sig_ext_perms"           => $fb_sig_ext_perms,
      	"fb_sig_api_key"             => $fb_sig_api_key,
      	"fb_sig_app_id"              => $fb_sig_app_id,
      	"fb_sig"                     => $fb_sig,               
      );
    
	}
		
}


sub LoadFarmLand {
	  
	  my $st;
	  my @MyArr;
	  foreach (keys %FaceBookAPPHs){
	  	 $st = $_."=".$FaceBookAPPHs{$_};
	  	 push (@MyArr, $st);
	  	}
	  	
	  $st = join("\&", @MyArr);
	  	
	  my $url = 'http://fbtwgw.farm.elex-tech.us/myfarm/facebook_tw/index.php?';
	     $url = $url.$st;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0");
    
    $ua->cookie_jar(HTTP::Cookies->new());
    #$ua->proxy();

   my $req = HTTP::Request->new(GET => $url);
   
       $req->header(  'Accept'          => '*/*',
                    'Accept-Language' => 'zh-TW',
                    'Accept-Encoding' => 'xml',
                    'User-Agent'      => 'Mozilla/4.0',
                    'Host'            => 'fbtwgw.farm.elex-tech.us',
                  );
       
   my $cont = $FarmAPPHs{"fb_sig_api_key"}."_expires=".$FarmAPPHs{"fb_sig_expires"}.";"."\n".
              $FarmAPPHs{"fb_sig_api_key"}."_session_key=".$FarmAPPHs{"fb_sig_session_key"}.";"."\n".
              $FarmAPPHs{"fb_sig_api_key"}."_user=".$FarmAPPHs{"fb_sig_user"};             


       $req->content($cont);
         
  my $res = $ua->request($req);
       
#  print $res->as_string;
       
 if($res->is_success){
 	 print "Load FarmLand ok...\n";
} else {
	 print "Load FarmLand fail ...\n".$res->status_line;
	}
	
	#print $res->content;
	
	#Parse Falsh
	my $cont = $res->content;
  open (ohtml,">test.html") || die;
  printf ohtml ($cont);
  
  
  my @MyArr = split("\n",$cont);
 
   my ($version      ,$firstPlay    ,$uid          ,$sig_user        ,$sig_session_key);
   my ($sig_api_key  ,$host         ,$hweb_base    ,$database        ,$sig_time);
   my ($mod          ,$farmuid      ,$secretid     ,$sig_ss          ,$sig_photo_upload);
   my ($locale       ,$appurl       ,$ga_account   ,$invitefriendsURL,$ga_path);
   
 foreach $a (@MyArr){
  	    $a =~ s/\s+//g;
  	    $a =~ s/\"//g;
  	    
     if($a =~ m/version:(\S+)\,/               ){ $version    =$1; }
  elsif($a =~ m/firstPlay:(\S+)\, /            ){ $firstPlay  =$1; }    
  elsif($a =~ m/uid:(\S+)\,/                   ){ $uid        =$1; }
  elsif($a =~ m/sig_user:(\S+)\,/              ){ $sig_user   =$1; }
  elsif($a =~ m/sig_session_key:(\S+)\,/       ){ $sig_session_key =$1; } #5
  elsif($a =~ m/sig_api_key:(\S+)\,/           ){ $sig_api_key =$1; }
  elsif($a =~ m/host:(\S+)\,/                  ){ $host        =$1; }
  elsif($a =~ m/hweb_base:(\S+)\,/             ){ $hweb_base   =$1; }
  elsif($a =~ m/database:(\S+)\,/              ){ $database    =$1; }
  elsif($a =~ m/sig_time:(\S+)\,/              ){ $sig_time    =$1; } #5
  elsif($a =~ m/mod:(\S+)\,/                   ){ $mod         =$1; }
  elsif($a =~ m/farmuid:(\S+)\,/               ){ $farmuid     =$1; }
  elsif($a =~ m/secretid:(\S+)\,/              ){ $secretid    =$1; }
  elsif($a =~ m/sig_ss:(\S+)\,/                ){ $sig_ss      =$1; }
  elsif($a =~ m/sig_photo_upload:(\S+)\,/      ){ $sig_photo_upload =$1;} #5
  elsif($a =~ m/locale:(\S+)\,/                ){ $locale      =$1; }
  elsif($a =~ m/appurl:(\S+)\,/                ){ $appurl       =$1; }
  elsif($a =~ m/ga_account:(\S+)\,/            ){ $ga_account   =$1; }
  elsif($a =~ m/invitefriendsURL:(\S+)\,/      ){ $invitefriendsURL =$1;}
  elsif($a =~ m/ga_path:(\S+)\,/               ){ $ga_path      =$1; }
}
 
 
     %FarmAPPHs = (
        "version"         => $version,
        "firstPlay"       => $firstPlay,
        "uid"             => $uid,
        "sig_user"        => $sig_user,
        "sig_session_key" => $sig_session_key,
        "sig_api_key"     => $sig_api_key,
        "host"            => $host,
        "hweb_base"       => $hweb_base,
        "database"        => $database,
        "sig_time"        => $sig_time,
        "mod"             => $mod,
        "farmuid"         => $farmuid,
        "secretid"        => $secretid,
        "sig_ss"          => $sig_ss,
        "sig_photo_upload" => $sig_photo_upload,
        "locale"          => $locale,
        "appurl"          => $appurl,
        "ga_account"      => $ga_account,
        "invitefriendsURL"=> $invitefriendsURL,
        "ga_path"         => $ga_path,
     );
}


sub LoadItems{
	my $url = 'http://img.harvest.6waves.com/farmgame_tw/static/swf_2_1/database/v0321/item.xml?4';
	
  my $ua = LWP::UserAgent->new;
     $ua->agent("Mozilla/5.0");
    
     #$ua->cookie_jar(HTTP::Cookies->new());
     
       my $req = HTTP::Request->new(GET => $url);
	
	
       $req->header(  'Accept'          => '*/*',
                      'Accept-Encoding' => 'xml',
                      'Host'        => 'img.harvest.6waves.com'
                  );
	
	 my $res = $ua->request($req);
       
       
 if($res->is_success){
 	 print "Load Items Inf ok...\n";
} else {
	 print "Load Items Inf fail ...\n".$res->status_line;
	}
      
      #print $res->content;
      
      open (oItem,">Item.xml") || die;
 	    printf oItem ($res->as_string);	
}


sub LoadFarmLandInf {
	  my $url = 'http://fbtwgw.farm.elex-tech.us/new_2_1_1/data/gateway.php';

    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0");
    
    $ua->cookie_jar(HTTP::Cookies->new());
    #$ua->proxy();

   my $req = HTTP::Request->new(POST => $url);
   
       $req->header(  'Accept'          => '*/*',
                    'Accept-Language' => 'zh-TW',
                    'Accept-Encoding' => 'xml',
                    'Referer'         => $FarmAPPHs{"host"},
                    'Content-Type'    => 'application/x-amf',
                  );
             
   my $cont = '.......'."\n".
              'user.loadFarm../1....'."\n".
              '.....'."\n".
              '...k.'.'A2E514E3922FC8141E5D43DADA51A54D8'.
              '.t..'.int($FarmAPPHs{"sig_time"}).
              '.v..'.$FarmAPPHs{"version"}.
              '.authcode..'.$FarmAPPHs{"secretid"}.
              '.l..'.$FarmAPPHs{"locale"}.
              '.farmuid..'.$FarmAPPHs{"farmuid"}.
              '.uid..'.$FarmAPPHs{"uid"};
            
      $req->content($cont);
 
         
  my $res = $ua->request($req);
       
  print $res->as_string;
       
 if($res->is_success){
 	 print "Load FarmLand Inf ok...\n";
} else {
	 print "Load FarmLand Inf fail ...\n".$res->status_line;
	}
		
	
	}
 

