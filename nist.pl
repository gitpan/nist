#!/usr/local/bin/perl
#        $Id: nist.pl,v 1.12 2000/02/07 07:02:18 j Exp $
#
# Nist.pl to keep your system time up to date by using time servers.
# Copyright (C) 1998, 1999, 2000 Ali Onur Cinar <root@zdo.com>
# Y2K fixes by Frank Denis aka Jedi/Sector One <j@4u.net>
#
# Latest version can be downloaded from:
#
#   http://www.zdo.com
#   ftp://hun.ece.drexel.edu/pub/cinar/nist*
#   ftp://ftp.cpan.org/pub/CPAN/authors/id/A/AO/AOCINAR/nist*
#   ftp://sunsite.unc.edu/pub/Linux/system/admin/timei/nist*
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. And also
# please DO NOT REMOVE my name, and give me a CREDIT when you use
# whole or a part of this program in an other program.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

use Socket qw(PF_INET SOCK_STREAM AF_INET);
use POSIX qw(mktime);

$timeserver = 'time_a.timefreq.bldrdoc.gov';	# time server
$port = '13';					# time port (default:13)
$timediff = '+01:00:00';			# time differance
$datepr = '/bin/date';				# full path of date


$timediff =~/(.)(..).(..).(..)/g;
$diff = (($2*3600)+($3*60)+$4);
$diff = "$1$diff";

if ($> ne 0)
{
	print STDERR "This program should run as root user to be able to update sytem date.\n"; 
#	exit;
}

if ($timeserver =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/)
{
	$timeserver_addr = pack('C4', $1, $2, $3, $4);
} else {
	$timeserver_addr = gethostbyname($timeserver);
}

print "Connecting to $timeserver on port $port...\n";

if (!socket(NIST, AF_INET, SOCK_STREAM, getprotobyname("tcp") || 6))
{
	print "socket failed ($!)\n"; exit;;
}

if (!connect(NIST, pack('Sna4x8', AF_INET, $port, $timeserver_addr)))
{
	print "connect to $timeserver failed ($!)\n"; exit;
}

while (<NIST>)
{
	$time_data_raw = $_;
	last if ( /NIST/);
}

close NIST;

$time_data_raw =~ /.{6}(..).(..).(..).(..).(..).(..)/g;
print "Current GMT is $1-$2-$3 $4-$5-$6\n";

&DateToSec($1,$2,$3,$4,$5,$6);
$datsec += $diff;
&SecToDate($datsec);

printf "Local time is  %02d-%02d-%02d %02d-%02d-%02d\n", $year, $month, $day, $hour, $min, $sec;
print "Updating the system time. ";
$date_command = sprintf ("$datepr %02d%02d%02d%02d%04d.%02d",$month, $day, $hour,$min, $year, $sec);
system ($date_command);
print "Done.\n";

sub DateToSec
{
	$year = @_[0];$month = @_[1];$day = @_[2];
	$hour = @_[3];$min = @_[4];$sec = @_[5];
	$datsec = POSIX::mktime($sec, $min, $hour, $day - 1, $month - 1, $year + 100);
}

sub SecToDate
{
	$datsec = @_[0];
	($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = localtime($datsec);
	$day++;
	$month++;
	$year += 1900;
}
