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

$gCmdinfo->AddCommand('global','options common to all commands');
$gCmdinfo->AddCommandParams('global','-u|--url',' <string>','URL for simian grid functions');

# -----------------------------------------------------------------
# NAME: CheckGlobals
# DESC: Check to make sure all of the required globals are set
# -----------------------------------------------------------------
sub CheckGlobals
{
    my $cmd = shift(@_);

    $gSimianURL = $ENV{'SIMIAN'} unless defined $gSimianURL;
    if (! defined $gSimianURL)
    {
        $gCmdinfo->DumpCommands(undef,"No Simian URL specified, please set SIMIAN environment variable");
    }

    $gSimian = Simian->new(URL => $gSimianURL);
}
    
# -----------------------------------------------------------------
# NAME: GetScene
# DESC: Get scene information by name or uuid
# -----------------------------------------------------------------
sub GetScene
{
    my ($uuid,$name,$cmd) = @_;

    return $gSimian->GetScene($uuid,'SceneID') if defined $uuid;
    return $gSimian->GetScene($name,'Name') if defined $name;

    $gCmdinfo->DumpCommands($cmd,'Missing scene identifier (name or uuid)');

    return undef;
}
    
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
## Commands
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# -----------------------------------------------------------------
# NAME: cLISTSCENES
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('list','list scenes by name');
$gCmdinfo->AddCommandParams('list','-n|--name',' <string>','scene full name');

sub cLISTSCENES
{
    my $gAllFields = 1;
    my $gFieldList = {};

    my $name;

    $gOptions->{'n|name=s'} = \$name;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('list',"Unknown option");
    }

    &CheckGlobals;

    foreach my $fld (@ARGV)
    {
        $gAllFields = 0;
        $gFieldList->{$fld} = 1;
    }

    $gCmdinfo->DumpCommands('list','Missing name parameter')
        unless defined $name;

    my $json = JSON->new->pretty->allow_nonref;

    my $list = $gSimian->GetSceneList($name);
    foreach my $scene (@{$list})
    {
        foreach my $key (sort keys %{$scene})
        {
            # is this a field we need to show
            if ($gAllFields || $gFieldList->{$key})
            {
                # attempt to decode json string, if it fails then just print the string
                my $val;
                eval { $val = $json->encode($scene->{$key}); };
                printf("$key ==> $val\n");
            }
        }
        print "\n";
    }
}

# -----------------------------------------------------------------
# NAME: cDUMPSCENE
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('dump','dump information about a scene');
$gCmdinfo->AddCommandParams('dump','-i|--uuid',' <string>','scene uuid');
$gCmdinfo->AddCommandParams('dump','-n|--name',' <string>','scene full name');

sub cDUMPSCENE
{
    my $gAllFields = 1;
    my $gFieldList = {};

    my $name;
    my $uuid;

    $gOptions->{'i|uuid=s'} = \$uuid;
    $gOptions->{'n|name=s'} = \$name;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('dump',"Unknown option");
    }

    &CheckGlobals;

    foreach my $fld (@ARGV)
    {
        $gAllFields = 0;
        $gFieldList->{$fld} = 1;
    }

    my $json = JSON->new->pretty->allow_nonref;
    my $scene = &GetScene($uuid,$name,'dump');

    foreach my $key (sort keys %{$scene})
    {
        # is this a field we need to show
        if ($gAllFields || $gFieldList->{$key})
        {
            # attempt to decode json string, if it fails then just print the string
            my $val;
            eval { $val = $json->encode($scene->{$key}); };
            printf("$key ==> $val\n");
        }
    }
}

# -----------------------------------------------------------------
# NAME: cRESERVESCENE
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('reserve','place a disabled region in the map to hold a space');
$gCmdinfo->AddCommandParams('reserve','-n|--name',' <string>','scene full name');
$gCmdinfo->AddCommandParams('reserve','-x',' <integer>','scene x coordinate (in region blocks)');
$gCmdinfo->AddCommandParams('reserve','-y',' <integer>','scene y coordinate (in region blocks)');

sub cRESERVESCENE
{
    my $name;
    my ($xcoord, $ycoord);

    $gOptions->{'n|name=s'} = \$name;
    $gOptions->{'x=i'} = \$xcoord;
    $gOptions->{'y=i'} = \$ycoord;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('reserve',"Unknown option");
    }

    &CheckGlobals;

    $gCmdinfo->DumpCommands('reserve','Missing required parameter (name, x, y)')
        unless defined $name && defined $xcoord && defined $ycoord;

    my $uuid = `uuidgen`;
    chomp($uuid);

    my ($xmin, $ymin, $xmax, $ymax) =
        ($xcoord*256, $ycoord*256, ($xcoord+1)*256, ($ycoord+1)*256);

    my @minp = ($xmin, $ymin, 0);
    my @maxp = ($xmax, $ymax, 4090);

    $gSimian->AddScene($uuid,$name,\@minp,\@maxp);
}

# -----------------------------------------------------------------
# NAME: cREMOVESCENE
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('remove','remove scene reservation from database');
$gCmdinfo->AddCommandParams('remove','-i|--uuid',' <string>','scene uuid');
$gCmdinfo->AddCommandParams('remove','-n|--name',' <string>','scene full name');

sub cREMOVESCENE
{
    my $name;
    my $uuid;

    $gOptions->{'i|uuid=s'} = \$uuid;
    $gOptions->{'n|name=s'} = \$name;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('remove',"Unknown option");
    }

    &CheckGlobals;

    $gSimian->RemoveScene($uuid,'SceneID'), return if defined $uuid;
    $gSimian->RemoveScene($name,'Name'), return if defined $name;

    $gCmdinfo->DumpCommands('remove',"Missing required parameter (name or uuid)");
}

# -----------------------------------------------------------------
# NAME: cDISABLESCENE
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('disable','dump information about a scene');
$gCmdinfo->AddCommandParams('disable','-i|--uuid',' <string>','scene uuid');
$gCmdinfo->AddCommandParams('disable','-n|--name',' <string>','scene full name');

sub cDISABLESCENE
{
    my $name;
    my $uuid;

    $gOptions->{'i|uuid=s'} = \$uuid;
    $gOptions->{'n|name=s'} = \$name;
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('disable',"Unknown option");
    }

    &CheckGlobals;

    $gSimian->EnableScene($uuid,'SceneID',0), return if defined $uuid;
    $gSimian->EnableScene($name,'Name',0), return if defined $name;

    $gCmdinfo->DumpCommands('disable','Missing scene identifier (name or uuid)');
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
    
    &cLISTSCENES, exit		if ($paramCmd =~ m/^list$/i);
    &cDUMPSCENE, exit		if ($paramCmd =~ m/^dump$/i);

    &cRESERVESCENE, exit        if ($paramCmd =~ m/^reserve$/i);
    &cREMOVESCENE, exit         if ($paramCmd =~ m/^remove$/i);
    &cDISABLESCENE, exit        if ($paramCmd =~ m/^disable$/i);

    &cHELP;
}

&Main;



