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

# these describe how the user is identified
my $gIDValue;
my $gIDType;

my $gAvatarEmail;
my $gAvatarName;
my $gAvatarUUID;
my $gSimianURL;
my $gSimian;

my $gOptions = {
    'e|email=s'         => \$gAvatarEmail,
    'i|uuid=s'          => \$gAvatarUUID,
    'n|name=s'		=> \$gAvatarName,
    'u|url=s' 		=> \$gSimianURL
};

my $gCmdinfo = Helper::CommandInfo->new(USAGE => "USAGE: $gCommand <command> <options>");

$gCmdinfo->AddCommand('globals','options common to all commands');
$gCmdinfo->AddCommandParams('globals','-e|--email',' <string>','email address, must be unique');
$gCmdinfo->AddCommandParams('globals','-i|--uuid',' <string>','avatars uuid');
$gCmdinfo->AddCommandParams('globals','-n|--name',' <string>','avatars full name');
$gCmdinfo->AddCommandParams('globals','-u|--url',' <string>','URL for simian grid functions');

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

    $gIDValue = $gAvatarEmail, $gIDType = 'Email' if defined $gAvatarEmail;
    $gIDValue = $gAvatarName, $gIDType = 'Name' if defined $gAvatarName;
    $gIDValue = $gAvatarUUID, $gIDType = 'UserID' if defined $gAvatarUUID;

    if (! defined $gIDValue)
    {
        $gCmdinfo->DumpCommands(undef,"Avatar name not fully specified");
    }

    $gSimian = Simian->new(URL => $gSimianURL);
}
    
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
## Commands
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# -----------------------------------------------------------------
# NAME: cLISTUSERS
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('list','list users by name');

sub cLISTUSERS
{
    my $gAllFields = 1;
    my $gFieldList = {};

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


    my $json = JSON->new->pretty->allow_nonref;
    
    my $userlist = $gSimian->GetUserList($gAvatarName);
    foreach my $user (@{$userlist})
    {
        my $val = "";
        foreach my $key (qw/Name UserID Email AccessLevel/)
        {
            # is this a field we need to show
            if ($gAllFields || $gFieldList->{$key})
            {
                $val .= ($val eq "" ? "" : ",") . $user->{$key};
            }
        }
        print $val . "\n";
    }
}

# -----------------------------------------------------------------
# NAME: cDUMPUSER
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('dump','dump all UserData fields');
$gCmdinfo->AddCommandParams('dump','-r|--raw','','dump in raw JSON');

sub cDUMPUSER
{
    my $gRawData = 0;
    my $gAllFields = 1;
    my $gFieldList = {};

    $gOptions->{'r|raw!'} = \$gRawData;
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
    
    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    my $json = JSON->new->pretty->allow_nonref;
    foreach my $key (sort keys %{$info})
    {
        # is this a field we need to show
        if ($gAllFields || $gFieldList->{$key})
        {
            # attempt to decode json string, if it fails then just print the string
            my $val = $info->{$key};
            if (! $gRawData)
            {
                eval { $val = $json->encode($json->decode($val)); };
                $val .= "\n" if $@;
            }
            else
            {
                $val .= "\n";
            }
            printf("$key ==> $val");
        }
    }

}

# -----------------------------------------------------------------
# NAME: cCREATEUSER
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('create','create a new user in the database');
$gCmdinfo->AddCommandParams('create','-p|--password',' <string>','user password');
$gCmdinfo->AddCommandParams('create','-t|--type',' <string>','avatar type (DefaultAvatar)');
$gCmdinfo->AddCommandParams('create','-a|--access',' <integer>','access level');

sub cCREATEUSER
{
    my $access = 0;
    my $passwd;
    my $avtype = "DefaultAvatar";

    $gOptions->{'a|access=i'} = \$access;
    $gOptions->{'p|password=s'} = \$passwd;
    $gOptions->{'t|type=s'} = \$avtype;

    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('create','Unknown option');
    }

    &CheckGlobals;

    $gCmdinfo->DumpCommands('create','missing email or password')
        unless (defined $gAvatarEmail && defined $passwd && defined $avtype);
    
    my $cred1 = '$1$' . md5_hex($passwd);
    my $cred2 = md5_hex($gAvatarName . ':Inventory:' . $passwd);

    my $uuid = `uuidgen`;
    chomp($uuid);

    $gSimian->AddUser($uuid,$gAvatarName,$gAvatarEmail,$access);
    $gSimian->AddIdentity($uuid,'md5hash',$gAvatarName,$cred1);
    $gSimian->AddIdentity($uuid,'a1hash',$gAvatarName,$cred2);
    $gSimian->CreateAvatar($uuid,$avtype);
}

# -----------------------------------------------------------------
# NAME: cREMOVEUSER
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('remove','remove a user from the database');

sub cREMOVEUSER
{
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('remove','Unknown option');
    }

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    $gSimian->RemoveUser($uuid);
    $gSimian->RemoveInventoryNode($uuid,$uuid); # this is the root for this user
}

# -----------------------------------------------------------------
# NAME: cUPDATEUSER
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('update','update basic user information in the database');
$gCmdinfo->AddCommandParams('update','-a|--access',' <integer>','access level');

sub cUPDATEUSER
{
    my $access = 0;

    $gOptions->{'a|access=i'} = \$access;
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('create','Unknown option');
    }

    &CheckGlobals;

    # must use UUID for identification
    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    $gAvatarName = $info->{"Name"} unless defined $gAvatarName;
    $gAvatarEmail = $info->{"Email"} unless defined $gAvatarEmail;

    $gSimian->AddUser($uuid,$gAvatarName,$gAvatarEmail,$access);
}

# -----------------------------------------------------------------
# NAME: cRESETUSER
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('reset','reset user inventory and appearance');
$gCmdinfo->AddCommandParams('reset','-t|--type',' <string>','avatar type (DefaultAvatar)');

sub cRESETUSER
{
    my $avtype = "DefaultAvatar";

    $gOptions->{'t|type=s'} = \$avtype;
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('reset','Unknown option');
    }

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};

    # get rid of the packed appearance for the user
    $gSimian->RemoveUserData($uuid,'LLPackedAppearance');

    # get rid of the old inventory, we'll overwrite it anyway
    $gSimian->RemoveInventoryNode($uuid,$uuid); # this is the root for this user

    # and create it all over again
    $gSimian->CreateAvatar($uuid,$avtype);
}

# -----------------------------------------------------------------
# NAME: cSETUSERDATA
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('set ','set the value of a field in the UserData table');
$gCmdinfo->AddCommandParams('set ','-k|--key',' <string>','key to add');
$gCmdinfo->AddCommandParams('set ','-v|--val',' <string>','value to set for the key');

sub cSETUSERDATA
{
    my $key;
    my $val;

    $gOptions->{'k|key=s'} = \$key;
    $gOptions->{'v|val=s'} = \$val;

    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('set ','Unknown option');
    }

    &CheckGlobals;

    $gCmdinfo->DumpCommands('set ', 'missing key or val parameter')
        unless defined $key && defined $val;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    $gSimian->AddUserData($uuid,$key,$val);
}

# -----------------------------------------------------------------
# NAME: cUNSETUSERDATA
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('unset','remove a key from the UserData table');
$gCmdinfo->AddCommandParams('unset','-k|--key',' <string>','key to remove');

sub cUNSETUSERDATA
{
    my $key;

    $gOptions->{'k|key=s'} = \$key;
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('unset','Unknown option');
    }

    $gCmdinfo->DumpCommands('unset','missing <key> parameter')
        unless defined $key;

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    $gSimian->RemoveUserData($uuid,$key);
}

# -----------------------------------------------------------------
# NAME: cBANUSER
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('ban ','set the ban flag for a user');

sub cBANUSER
{
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('ban ','Unknown option');
    }

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    my $flags = {};
    if (defined $info->{"UserFlags"})
    {
        $flags = decode_json($info->{"UserFlags"});
    }
    $flags->{'Suspended'} = JSON::true;

    $gSimian->AddUserData($uuid,'UserFlags',encode_json($flags));
}

# -----------------------------------------------------------------
# NAME: cUNBANUSER
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('unban','unset the ban flag for a user');

sub cUNBANUSER
{
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('unban','Unknown option');
    }

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    my $flags = {};
    if (defined $info->{"UserFlags"})
    {
        $flags = decode_json($info->{"UserFlags"});
    }
    $flags->{'Suspended'} = JSON::false;

    $gSimian->AddUserData($uuid,'UserFlags',encode_json($flags));
}

# -----------------------------------------------------------------
# NAME: cIDENT
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('ident','dump the list of identities for this user');
$gCmdinfo->AddCommandParams('ident','-r|--raw','','dump in raw JSON');

sub cIDENT
{
    my $gRawData = 0;

    $gOptions->{'r|raw!'} = \$gRawData;
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('ident','Unknown option');
    }

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    my $ids = $gSimian->GetIdentities($uuid);
    if ($gRawData)
    {
        print encode_json($ids) . "\n";
    }
    else
    {
        my $json = JSON->new->pretty->allow_nonref;
        print $json->encode($ids) . "\n";
    }
}

# -----------------------------------------------------------------
# NAME: cPASSWD
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('passwd','set the password for this user');
$gCmdinfo->AddCommandParams('passwd','-p|--password',' <string>','user password');

sub cPASSWD
{
    my $passwd;

    $gOptions->{'p|password=s'} = \$passwd;
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('passwd','Unknown option');
    }

    &CheckGlobals;

    $gCmdinfo->DumpCommands('passwd','missing <password> parameter')
        unless defined $passwd;

    my $cred1 = '$1$' . md5_hex($passwd);
    my $cred2 = md5_hex($gAvatarName . ':Inventory:' . $passwd);

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    $gSimian->AddIdentity($uuid,'md5hash',$gAvatarName,$cred1);
    $gSimian->AddIdentity($uuid,'a1hash',$gAvatarName,$cred2);
}

# -----------------------------------------------------------------
# NAME: cINVENTORY
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('inventory','dump the users inventory');
sub cINVENTORY
{
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('inventory','Unknown option');
    }

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    
    my $params = {
        'IncludeFolders' => 1,
        'IncludeItems' => 0,
        'ChildrenOnly' => 1
    };

    my $indent = 0;
    my %folders;
    $folders{$uuid}{'indent'} = $indent;
    $folders{$uuid}{'name'} = 'My Inventory';

    my @itemQ = ( $uuid );
    
    while (@itemQ)
    {
        my $itemID = shift(@itemQ);
        my $items = $gSimian->GetInventoryNode($itemID,$uuid,$params);

        $indent = $folders{$itemID}{'indent'} || 0;
        print ' ' x $indent . $folders{$itemID}{'name'} . "\n";

        foreach my $item (sort { $b->{'Name'} cmp $a->{'Name'} } @{$items})
        {
            my $id = $item->{"ID"};
            next if $item->{"Type"} ne "Folder";

            next if $id eq $itemID;
            unshift(@itemQ,$id);

            $folders{$id}{'indent'} = $indent + 4;
            $folders{$id}{'name'} = $item->{"Name"};
        }
    }
}

# -----------------------------------------------------------------
# NAME: cLISTSESSIONS
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('session-list','list current sessions');

sub cLISTSESSIONS
{
    my $gAllFields = 1;
    my $gFieldList = {};

    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('session-list',"Unknown option");
    }

    &CheckGlobals;

    foreach my $fld (@ARGV)
    {
        $gAllFields = 0;
        $gFieldList->{$fld} = 1;
    }


    my $json = JSON->new->pretty->allow_nonref;
    
    my $sesslist = $gSimian->GetSessionList();
    foreach my $sess (@{$sesslist})
    {
        if ($gAllFields || $gFieldList->{'UserName'})
        {
            my $userid = $sess->{'UserID'};
            if (defined $userid)
            {
                my $user = $gSimian->GetUser($userid,'UserID');
                $sess->{'UserName'} = (defined $user && defined $user->{'Name'}) ? $user->{'Name'} : 'Unknown';
            }        
        }

        if ($gAllFields || $gFieldList->{'SceneName'})
        {
            my $sceneid = $sess->{'SceneID'};
            if (defined $sceneid)
            {
                my $scene = $gSimian->GetScene($sceneid,'SceneID');
                $sess->{'SceneName'} = (defined $scene && defined $scene->{'Name'}) ? $scene->{'Name'} : "Unknown";
            }
        }

        my $val = "";
        foreach my $key (qw/UserID UserName SceneID SceneName SessionID LastUpdate/)
        {
            # is this a field we need to show
            if ($gAllFields || $gFieldList->{$key})
            {
                my $v = $sess->{$key};
                $val .= ($val eq "" ? "" : ",") . $v;
            }
        }
        print $val . "\n";
    }
}

# -----------------------------------------------------------------
# NAME: cREMOVESESSION
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('session-remove','remove a user session from the database');

sub cREMOVESESSION
{
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('session-remove','Unknown option');
    }

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    $gSimian->RemoveSession($uuid,'UserID');
}

# -----------------------------------------------------------------
# NAME: cDUMPSESSION
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('session-dump','get information about a users sessions');
$gCmdinfo->AddCommandParams('session-dump','-r|--raw','','dump in raw JSON');

sub cDUMPSESSION
{
    my $gRawData = 0;
    my $gAllFields = 1;
    my $gFieldList = {};

    $gOptions->{'r|raw!'} = \$gRawData;
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('session-dump','Unknown option');
    }

    &CheckGlobals;

    foreach my $fld (@ARGV)
    {
        $gAllFields = 0;
        $gFieldList->{$fld} = 1;
    }
    
    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    my $results = $gSimian->GetSession($uuid,'UserID');

    my $json = JSON->new->pretty->allow_nonref;

    foreach my $key (sort keys %{$results})
    {
        # is this a field we need to show
        if ($gAllFields || $gFieldList->{$key})
        {
            # attempt to decode json string, if it fails then just print the string
            my $val = $results->{$key};
            if (! $gRawData)
            {
                eval { $val = $json->encode($val); };
            }
            printf("$key ==> $val\n");
        }
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
    
    &cLISTUSERS, exit		if ($paramCmd =~ m/^list$/i);
    &cCREATEUSER, exit		if ($paramCmd =~ m/^create$/i);
    &cREMOVEUSER, exit		if ($paramCmd =~ m/^remove$/i);
    &cRESETUSER, exit		if ($paramCmd =~ m/^reset$/i);
    &cUPDATEUSER, exit		if ($paramCmd =~ m/^update$/i);

    &cLISTSESSIONS, exit	if ($paramCmd =~ m/^session-list$/i);
    &cREMOVESESSION, exit       if ($paramCmd =~ m/^session-remove$/i);
    &cDUMPSESSION, exit         if ($paramCmd =~ m/^session-dump$/i);

    &cDUMPUSER, exit		if ($paramCmd =~ m/^dump$/i);
    &cSETUSERDATA, exit		if ($paramCmd =~ m/^set$/i);
    &cUNSETUSERDATA, exit	if ($paramCmd =~ m/^unset$/i);

    &cBANUSER, exit		if ($paramCmd =~ m/^ban$/i);
    &cUNBANUSER, exit		if ($paramCmd =~ m/^unban$/i);

    &cIDENT, exit		if ($paramCmd =~ m/^ident$/i);
    &cPASSWD, exit		if ($paramCmd =~ m/^passwd$/i);

    &cINVENTORY, exit		if ($paramCmd =~ m/^inventory$/i);

    &cHELP;
}

&Main;



