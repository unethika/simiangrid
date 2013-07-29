#!/usr/bin/perl -w
# -----------------------------------------------------------------
# Copyright (c) 2010 Intel Corporation
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:

#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.

#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.

#     * Neither the name of the Intel Corporation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE INTEL OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# EXPORT LAWS: THIS LICENSE ADDS NO RESTRICTIONS TO THE EXPORT LAWS OF
# YOUR JURISDICTION. It is licensee's responsibility to comply with any
# export regulations applicable in licensee's jurisdiction. Under
# CURRENT (May 2000) U.S. export regulations this software is eligible
# for export from the U.S. and can be downloaded by or otherwise
# exported or reexported worldwide EXCEPT to U.S. embargoed destinations
# which include Cuba, Iraq, Libya, North Korea, Iran, Syria, Sudan,
# Afghanistan and any other country to which the U.S. has embargoed
# goods and services.
# -----------------------------------------------------------------

=head1 NAME

name

=head1 SYNOPSIS

synopsis

=head1 DESCRIPTION

description

=head2 COMMON OPTIONS

=head2 COMMANDS

=head1 CUSTOMIZATION

customization

=head1 SEE ALSO

see also

=head1 AUTHOR

Mic Bowman, E<lt>mic.bowman@intel.comE<gt>

=cut

use FindBin;
use lib "$FindBin::Bin/../lib";

my $gCommand = $FindBin::Script;

use JSON;
use Digest::MD5 qw(md5_hex);
use Getopt::Long;

use Simian;
use Helper::CommandInfo;

my $gSimianURL;
my $gSimian;

my $gOptions = {
    'u|url=s' 		=> \$gSimianURL
};

my $gCmdinfo = Helper::CommandInfo->new(USAGE => "USAGE: $gCommand <command> <options>");

$gCmdinfo->AddCommand('globals','options common to all commands');
$gCmdinfo->AddCommandParams('globals','-u|--url',' <string>','URL for simian grid functions');
$gCmdinfo->AddCommandParams('globals','-a|--auth',' <string>','authorization capability');

# -----------------------------------------------------------------
# NAME: CheckGlobals
# DESC: Check to make sure all of the required globals are set
# -----------------------------------------------------------------
sub CheckGlobals
{
    my $cmd = shift(@_);

    $gSimianURL = $ENV{'SIMIAN'} unless defined $gSimianURL;
    $gSimianCAP = $ENV{'SIMCAP'} unless defined $gSimianCAP;
    if (! defined $gSimianURL || ! defined $gSimianCAP)
    {
        $gCmdinfo->DumpCommands(undef,"No Simian URL specified, please set SIMIAN environment variable");
    }

    $gSimian = Simian->new(URL => $gSimianURL, CAP => $gSimianCAP);
}
    
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
## Commands
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# -----------------------------------------------------------------
# NAME: cCREATECAP
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('create','create a capability');
$gCmdinfo->AddCommandParams('create','-n|--name',' <string>','capability owners full name');
$gCmdinfo->AddCommandParams('create','-i|--uuid',' <string>','capability owners UUID');
$gCmdinfo->AddCommandParams('create','-r|--resource',' <string>','resource name');
$gCmdinfo->AddCommandParams('create','-s|--seconds',' <integer>','number of seconds before expiration');
$gCmdinfo->AddCommandParams('create','-d|--days',' <integer>','number of days before expiration');

sub cCREATECAP
{
    my $gAllFields = 1;
    my $gFieldList = {};

    my ($name, $uuid, $resource, $seconds, $days);

    $gOptions->{'i|uuid=s'} = \$uuid;
    $gOptions->{'n|name=s'} = \$name;
    $gOptions->{'r|resource=s'} = \$resource;
    $gOptions->{'d|days=i'} = \$days;
    $gOptions->{'s|seconds=i'} = \$seconds;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('create',"Unknown option");
    }

    &CheckGlobals;

    $gCmdinfo->DumpCommands('create',"resource and expiration time required")
        unless defined $resource && (defined $seconds || defined $days);

    $seconds = $days * 24 * 60 * 60 if defined $days;
    my $expire = time() + $seconds;

    my ($type, $value);
    $type = 'Name', $value = $name if defined $name;
    $type = 'UserID', $value = $uuid if defined $uuid;
    $gCmdinfo->DumpCommands('create',"Missing owner identifier") unless defined $type;

    my $info = $gSimian->GetUser($value,$type);
    $gCmdinfo->DumpCommands('create',"Unknown user $value") unless $info;

    my $capid = $gSimian->AddCapability($info->{'UserID'},$resource,$expire);
    print $capid . "\n";
}

# -----------------------------------------------------------------
# NAME: cDUMPCAP
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('dump','get a capability');
$gCmdinfo->AddCommandParams('dump','-c|--capability',' <string>','capability identifier');

sub cDUMPCAP
{
    my $gAllFields = 1;
    my $gFieldList = {};

    my $id;

    $gOptions->{'c|capability=s'} = \$id;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('dump',"Unknown option");
    }

    &CheckGlobals;

    $gCmdinfo->DumpCommands('dump',"missing capability identifier") unless defined $id;

    my $info = $gSimian->GetCapability($id);
    if (defined $info)
    {
        my $owner = $info->{'OwnerID'};
        my $uinfo = $gSimian->GetUser($owner,'UserID');
        my $name = $uinfo->{'Name'};
        my $resource = $info->{'Resource'};
        my $expire = localtime($info->{'Expiration'});

        print "$name,$owner,$resource,$expire\n";
    }
}

# -----------------------------------------------------------------
# NAME: cREVOKECAP
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('revoke','revoke a capability');
$gCmdinfo->AddCommandParams('revoke','-c|--capability',' <string>','capability identifier');

sub cREVOKECAP
{
    my $gAllFields = 1;
    my $gFieldList = {};

    my $id;

    $gOptions->{'c|capability=s'} = \$id;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('revoke',"Unknown option");
    }

    &CheckGlobals;

    $gCmdinfo->DumpCommands('revoke',"missing capability identifier") unless defined $id;

    $gSimian->RemoveCapability($id);
}

# -----------------------------------------------------------------
# NAME: cPURGECAPS
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('purge','revoke all capabilities for a user');
$gCmdinfo->AddCommandParams('purge','-n|--name',' <string>','capability owners full name');
$gCmdinfo->AddCommandParams('purge','-i|--uuid',' <string>','capability owners UUID');

sub cPURGECAPS
{
    my $gAllFields = 1;
    my $gFieldList = {};

    my ($name, $uuid);

    $gOptions->{'i|uuid=s'} = \$uuid;
    $gOptions->{'n|name=s'} = \$name;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('purge',"Unknown option");
    }

    &CheckGlobals;

    my ($type, $value);
    $type = 'Name', $value = $name if defined $name;
    $type = 'UserID', $value = $uuid if defined $uuid;
    $gCmdinfo->DumpCommands('purge',"Missing owner identifier") unless defined $type;

    my $info = $gSimian->GetUser($value,$type);
    $gCmdinfo->DumpCommands('purge',"Unknown user $value") unless $info;

    $gSimian->RemoveUserCapabilities($info->{'UserID'});
}

# -----------------------------------------------------------------
# NAME: cLISTCAPS
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('list','list all capabilities owned by a user');
$gCmdinfo->AddCommandParams('list','-n|--name',' <string>','capability owners full name');
$gCmdinfo->AddCommandParams('list','-i|--uuid',' <string>','capability owners UUID');

sub cLISTCAPS
{
    my $gAllFields = 1;
    my $gFieldList = {};

    my ($name, $uuid);

    $gOptions->{'i|uuid=s'} = \$uuid;
    $gOptions->{'n|name=s'} = \$name;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('list',"Unknown option");
    }

    &CheckGlobals;

    my ($type, $value);
    $type = 'Name', $value = $name if defined $name;
    $type = 'UserID', $value = $uuid if defined $uuid;
    $gCmdinfo->DumpCommands('list',"Missing owner identifier") unless defined $type;

    my $info = $gSimian->GetUser($value,$type);
    $gCmdinfo->DumpCommands('list',"Unknown user $value") unless $info;

    my $caplist = $gSimian->GetUserCapabilities($info->{'UserID'});
    foreach my $cap (@{$caplist})
    {
        my $capid = $cap->{'CapabilityID'};
        my $resource = $cap->{'Resource'};
        my $expire = localtime($cap->{'Expiration'});

        print "$capid,$resource,$expire\n";
    }
}

# -----------------------------------------------------------------
# NAME: Main
# -----------------------------------------------------------------
sub cHELP
{
    $gCmdinfo->DumpCommands();
}

# -----------------------------------------------------------------
# NAME: Main
# -----------------------------------------------------------------
sub Main
{
    my $paramCmd = ($#ARGV >= 0) ? shift @ARGV : "HELP";
    
    &cCREATECAP, exit		if ($paramCmd =~ m/^create$/i);
    &cDUMPCAP, exit		if ($paramCmd =~ m/^dump$/i);
    &cLISTCAPS, exit            if ($paramCmd =~ m/^list$/i);
    &cPURGECAPS, exit		if ($paramCmd =~ m/^purge$/i);
    &cREVOKECAP, exit		if ($paramCmd =~ m/^revoke$/i);

    &cHELP;
}

&Main;



