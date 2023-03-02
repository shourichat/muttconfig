#!/usr/bin/perl -w

use Date::Extract;
use Email::Abstract;
use Mail::Message;

#use DateTime::Format::Natural;

sub TryNextDayOfWeek {
	my $fullemail = $_[0];
	$fullemail =~ s/(mon|Mon|Tues|tues|Wednes|wednes|Thurs|thurs|Fri|fri)day.*/$1day/;
	$fullemail =~ s/.*\s(mon|Mon|Tues|tues|Wednes|wednes|Thurs|thurs|Fri|fri)day/$1day/;

	if($1) {
	use Date::Manip;
	my $date = ParseDate("next $fullemail");
	$date = UnixDate($date, "%d/%m/%Y");
	return($date);
	}
	else {
		return(0);
	}
}

my $iter = 0;

#### First get the email #####
open(my $femail, "<", "/home/shouri/tmp/email.txt");
my $email = Email::Abstract->new(join '', <$femail>);
my $msg = $email->cast("Mail::Message");
my $subject = $msg->head->study('subject');
#$from = $email->get_header("From");
$from = $msg->sender->format;
if($msg->body->isMultipart) {
	$a = $msg->body->part(0);
	$wholeemail = $a->decoded;
}
else {
	$wholeemail = $msg->body->decoded;
}

print "$from\n";
print "$subject\n";
###############################


#### Parse to find a future date ####
my $parser = Date::Extract->new(
	prefers => "future",
);
my $dt = $parser->extract($wholeemail)
	or die "No date found";
my $DDMMYYYY = $dt->dmy; 
my $dd = $dt->dmy; my $mo = $dt->dmy; my $yy = $dt->dmy;
$DDMMYYYY =~ s/-/\//g;
$dd =~ s/^(\d\d)-.*/$1/;
$mo =~ s/^\d\d-(\d\d)-.*/$1/;
$yy =~ s/^..-..-(.*)/$1/;

######################################


#### Now we need to look for the time ####

use DateTime;
$dt = DateTime->new( year => $yy, month => $mo, day => $dd, hour =>
23, minute => 59, second => 0, nanosecond => 0, time_zone =>
'Asia/Kolkata' );
my $epochtime  = $dt->epoch;

my $mm = ""; my $tt=""; my $hh=""; my $ampm=""; my $notvalid=0; 
my $notfound=1;
$wholeemail =~ s/\n/ /g;
$wholeemail =~ s/A\.M/AM/;
$wholeemail =~ s/a\.m/AM/;
$wholeemail =~ s/P\.M/PM/;
$wholeemail =~ s/p\.m/PM/;
$wholeemail =~ s/[Hh]ours/AM/;
while($notfound) {
	$wholeemail =~ m/(\d{1,2})[-:.]?(\d{0,2})[ ]*(am|AM|PM|pm|noon)/;
	if($1) {
		$hh = "$1"; 
		if($2) {
			$mm = "$2"; }
		else {
			$mm = "00"; }
		if($3) {
			$ampm = "$3";
			if($ampm =~ m/(pm|PM)/) {
				if($hh<12) {
				$hh = $hh+12; }
			}
			$notvalid = 0;
		}
		else {
		## If (no min and no ampm), then it is not valid
			if(!$2) {
				$notvalid=1;	
			}
		## If (min but no ampm), ok
		## If (no min but ampm), ok
		}
		if($hh !~ m/[0-9][0-9]/) {
			$hh = "0$hh";
		}
		$tt = "$hh:$mm";
		if(!$notvalid) { 
			$notfound = 0;
			print $tt, "\n"; 
		}
		else {
			$wholeemail =~ s/\d{1,2}/XX/;
		}
	}
	else {
		print "$DDMMYYYY\n";
		die "Could not extract time information.\n";
	}
}

$hh = $hh+1;
if($hh !~ m/[0-9][0-9]/) { $hh = "0$hh"; }

my $ttto = "$hh:$mm";

my $epochnow = time(); 
if($epochnow > $epochtime) {
	$DDMMYYYY = TryNextDayOfWeek($wholeemail);
}

print $DDMMYYYY, "\n";
print "Enter the above information in the calendar? y/n\n";
my $yn = <STDIN>;
if($yn =~ m/[yY]/) {
	system("khal new $DDMMYYYY $tt $ttto \"$subject\" :: \'$from\'\n");
}
else {
	print "Discarded.\n";
}

