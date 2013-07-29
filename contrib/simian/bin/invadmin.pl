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

use File::Spec;

my $gCommand = $FindBin::Script;

use JSON;
use Digest::MD5 qw(md5_hex);
use Getopt::Long;

use Simian;
use Helper::CommandInfo;

# these describe how the user is identified
my $gIDValue;
my $gIDType;

my $gAvatarName;
my $gAvatarUUID;
my $gSimianURL;
my $gSimian;

my $gOptions = {
    'i|uuid=s'          => \$gAvatarUUID,
    'n|name=s'		=> \$gAvatarName,
    'u|url=s' 		=> \$gSimianURL
};

my $gCmdinfo = Helper::CommandInfo->new(USAGE => "USAGE: $gCommand <command> <options>");

$gCmdinfo->AddCommand('globals','options common to all commands');
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

    $gIDValue = $gAvatarName, $gIDType = 'Name' if defined $gAvatarName;
    $gIDValue = $gAvatarUUID, $gIDType = 'UserID' if defined $gAvatarUUID;

    if (! defined $gIDValue)
    {
        $gCmdinfo->DumpCommands(undef,"Avatar name not fully specified");
    }

    $gSimian = Simian->new(URL => $gSimianURL);
}
    
# -----------------------------------------------------------------
# NAME: FindInventoryNodeByName
# -----------------------------------------------------------------
sub FindInventoryNodeByName
{
    my $uuid = shift(@_);
    my $itemID = shift(@_);
    my $pname = shift(@_);

    my $params = {
        'IncludeFolders' => 1,
        'IncludeItems' => 1,
        'ChildrenOnly' => 1
    };

    my $items = $gSimian->GetInventoryNode($itemID,$uuid,$params);
    foreach my $item (@{$items})
    {
        # return $item->{'ID'} if ($item->{'Name'} eq $pname) && ($item->{'Type'} eq "Folder");
        return $item->{'ID'} if $item->{'Name'} eq $pname;
    }

    die "unable to locate inventory node; $pname";
}

# -----------------------------------------------------------------
# NAME: FindInventoryNodeByPath
# -----------------------------------------------------------------
sub FindInventoryNodeByPath
{
    my $uuid = shift(@_);
    my $path = shift(@_);
    my @pathQ = File::Spec->splitdir($path);

    my $itemID = $uuid;
    while (@pathQ)
    {
        my $pname = shift(@pathQ);
        next if $pname eq "";

        $itemID = &FindInventoryNodeByName($uuid,$itemID,$pname);
    }
    
    return $itemID;
}

# -----------------------------------------------------------------
# NAME: CreateNotecardFromFile
# -----------------------------------------------------------------
sub CreateNotecardFromFile
{
    my $file = shift;

    # Read the file into the content string
    open(NCFILE,"<$file") || die "unable to locate notecard file; $file\n";
    my $content = do { local($/); <NCFILE> };
    close(NCFILE);

    my $length = length($content);
    return "Linden text version 2\n{\nLLEmbeddedItems version 1\n{\ncount 0\n}\nText length $length\n$content\n}";
}

## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
## Commands
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# -----------------------------------------------------------------
# NAME: cLSINVENTORY
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('ls','list the contents of a folder');
sub cLSINVENTORY
{
    my $path = "";
    my $long = 0;

    $gOptions->{'p|path=s'} = \$path;
    $gOptions->{'l|long!'} = \$long;

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
        'IncludeItems' => 1,
        'ChildrenOnly' => 1
    };

    my $indent = 0;

    my $root = &FindInventoryNodeByPath($uuid, $path);
    my $items = $gSimian->GetInventoryNode($root,$uuid,$params);

    my $thisitem = shift(@{$items}); # the first item is this folder

    # if there are no children then just use this item
    unless (@{$items})
    {
        print $thisitem->{"Name"} . ($thisitem->{"Type"} eq "Folder" ? "/ " : " ");
        print $thisitem->{"AssetID"} if $long && ($thisitem->{"Type"} ne "Folder");
        print "\n";
        return;
    }

   # there are children for the node
    my $size = 5;
    foreach my $item (@{$items})
    {
        my $nlen = length($item->{"Name"});
        $size = $nlen + 1 if $nlen >= $size;
    }

    foreach my $item (sort {
        return 1 if $a->{'Type'} ne "Folder" && $b->{'Type'} eq "Folder";
        return -1 if $a->{'Type'} eq "Folder" && $b->{'Type'} ne "Folder";
        return $a->{'Name'} cmp $b->{'Name'}
                      } @{$items})
    {
        printf ("%-*s",$size,$item->{"Name"} . ($item->{"Type"} eq "Folder" ? "/" : ""));
        if ($long && ($item->{"Type"} ne "Folder"))
        {
            print $item->{"AssetID"}
        }
        if ($long)
        {
            printf("%40s ",$item->{"ContentType"});
        }

        print "\n";
    }
}

# -----------------------------------------------------------------
# NAME: cLSINVENTORY
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('assetid','get the asset id for an item');
sub cGETASSETID
{
    my $path = "";

    $gOptions->{'p|path=s'} = \$path;
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('assetid','Unknown option');
    }

    &CheckGlobals;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    
    my $params = {
        'IncludeFolders' => 0,
        'IncludeItems' => 0,
        'ChildrenOnly' => 0
    };

    my $indent = 0;

    my $root = &FindInventoryNodeByPath($uuid, $path);
    my $items = $gSimian->GetInventoryNode($root,$uuid,$params);
    my $thisitem = shift(@{$items}); # the first item is this folder

    # if there are no children then just use this item
    print $thisitem->{"AssetID"} . "\n";
}

# -----------------------------------------------------------------
# NAME: cCREATEFOLDER
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('createfolder','create a new folder');
sub cCREATEFOLDER
{
    my $path = "";
    my $folder = undef;

    $gOptions->{'p|path=s'} = \$path;
    $gOptions->{'f|folder=s'} = \$folder;

    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('inventory','Unknown option');
    }

    &CheckGlobals;

    die "Missing required parameter; folder\n" unless $folder;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    my $parentID = &FindInventoryNodeByPath($uuid, $path);
    my $folderID = $gSimian->AddInventoryFolder($parentID,$uuid,$folder);

    print "Created $folderID\n";
}

# -----------------------------------------------------------------
# NAME: cCREATENOTECARD
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('createnotecard','create a notecard asset from a file');
sub cCREATENOTECARD
{
    my $pathtoasset = "";
    my $file = undef;

    $gOptions->{'p|path=s'} = \$pathtoasset;
    $gOptions->{'f|file=s'} = \$file;

    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('inventory','Unknown option');
    }

    &CheckGlobals;

    die "Missing required parameter; file\n" unless $file;

    my $info = $gSimian->GetUser($gIDValue,$gIDType);
    return unless defined $info;

    my $uuid = $info->{"UserID"};
    my ($vol, $path, $name) = File::Spec->splitpath($pathtoasset);
    my $parentID = &FindInventoryNodeByPath($uuid, $path);

    my $assetID = $gSimian->AddAsset($uuid,'application/vnd.ll.notecard',CreateNotecardFromFile($file));
    if (defined $assetID)
    {
        print "Created asset $assetID\n";

        my $itemID = $gSimian->AddInventoryItem($parentID,$uuid,$name,$assetID);
        if (defined $itemID)
        {
            print "Created inventory item $itemID\n";
        }
    }
}

# -----------------------------------------------------------------
# NAME: cDUMPINVENTORY
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('dumpinventory','dump the users inventory folder hierarchy');
sub cDUMPINVENTORY
{
    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('dumpinventory','Unknown option');
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
    $folders{$root}{'indent'} = $indent;
    $folders{$root}{'name'} = "My Inventory";

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
# NAME: cDUMPASSET
# -----------------------------------------------------------------
$gCmdinfo->AddCommand('dumpasset','dump an asset in a folder');
sub cDUMPASSET
{
    my $pathtoasset = "";
    my $metadata = 0;
    my $gAllFields = 1;
    my $gFieldList = {};

    $gOptions->{'p|path=s'} = \$pathtoasset;
    $gOptions->{'m|metadata!'} = \$metadata;

    if (! GetOptions(%{$gOptions}))
    {
        $gCmdinfo->DumpCommands('dumpasset','Unknown option');
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
    my ($vol, $path, $name) = File::Spec->splitpath($pathtoasset);

    my $root = &FindInventoryNodeByPath($uuid, $path);
    
    my $params = {
        'IncludeFolders' => 1,
        'IncludeItems' => 1,
        'ChildrenOnly' => 1
    };

    my $items = $gSimian->GetInventoryNode($root,$uuid,$params);
    shift(@{$items}); # the first item is this folder

    foreach my $item (@{$items})
    {
        if (($item->{"Name"} eq $name) && ($item->{"Type"} ne "Folder"))
        {
            if ($metadata)
            {
                my $results = $gSimian->GetAssetMetadata($item->{"AssetID"});
                foreach my $key (sort keys %{$results})
                {
                    # is this a field we need to show
                    print("$key = " . $results->{$key} . "\n") if $gAllFields || $gFieldList->{$key};
                }
            }
            else
            {
                print $gSimian->GetAsset($item->{"AssetID"});
            }
            last;
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
    
    &cLSINVENTORY, exit 	if ($paramCmd =~ m/^ls$/i);
    &cGETASSETID, exit 		if ($paramCmd =~ m/^assetid$/i);
    &cCREATEFOLDER, exit 	if ($paramCmd =~ m/^createfolder$/i || $paramCmd =~ m/^cf$/i);
    &cCREATENOTECARD, exit 	if ($paramCmd =~ m/^createnotecard$/i || $paramCmd =~ m/^cn$/i);

    &cDUMPINVENTORY, exit	if ($paramCmd =~ m/^dumpinventory$/i);
    &cDUMPASSET, exit 		if ($paramCmd =~ m/^dumpasset$/i);

    &cHELP;
}

&Main;



