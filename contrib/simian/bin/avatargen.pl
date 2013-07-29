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
use Getopt::Long;

use Simian;
use Helper::CommandInfo;

my $gRootItemID;
my $gAvatarInfo;
my $gAvatarAppearance;
my $gAvatarName;
my $gAvatarUUID;
my $gSimianURL;
my $gAvatarClassName = "NewAvatar";
my $gSimian;


my @gFolderQueue;		# Queue of folders to process

my @gFolderList;		# Order list of folders to create
my $gFolderInfo;		# Information about each folder

my @gItemList;			# Order list of items to create
my $gItemInfo;			# Information about each item

my $gLabelCount = 0;

# -----------------------------------------------------------------
# NAME: GetAvatarID
# -----------------------------------------------------------------
sub CleanString()
{
    my $str = shift(@_);
    $str =~ s/['"]//g;
    $str =~ s/  +/ /g;
    return $str;
}

# -----------------------------------------------------------------
# NAME: GetSubFolders
# -----------------------------------------------------------------
sub GetSubFolders()
{
    my ($itemID,$ownerID) = @_;
    
    my $params = {
        'IncludeFolders' => 1,
        'IncludeItems' => 0,
        'ChildrenOnly' => 1
    };

    print STDERR "Retrieving inventory folders from $itemID\n";

    my $items = $gSimian->GetInventoryNode($itemID,$ownerID,$params);
    foreach my $item (@{$items})
    {
	my $id = $item->{"ID"};
	next if $item->{"Type"} ne "Folder";

	next if $id eq $itemID;
	push(@gFolderQueue,$id);
	$gFolderInfo->{$id}->{"Name"} = $item->{"Name"};
	$gFolderInfo->{$id}->{"ContentType"} = $item->{"ContentType"};

	my $pid = $item->{"ParentID"};
# 	if (! defined $gFolderInfo->{$pid}->{"_LABEL"})
# 	{
# 	    $gFolderInfo->{$pid}->{"_LABEL"} = "parent_" . $gLabelCount++;
# 	}
	$gFolderInfo->{$id}->{"ParentID"} = $gFolderInfo->{$pid}->{"_LABEL"};
	$gFolderInfo->{$id}->{"_LABEL"} = "parent_" . $gLabelCount++;

    }
}

# -----------------------------------------------------------------
# NAME: GetFolderItems
# -----------------------------------------------------------------
sub GetFolderItems()
{
    my ($itemID,$ownerID) = @_;

    my $params = {
        'IncludeFolders' => 1,
        'IncludeItems' => 1,
        'ChildrenOnly' => 1
    };

    print STDERR "Retrieving inventory items from $itemID\n";

    my $items = $gSimian->GetInventoryNode($itemID,$ownerID,$params);
    foreach my $item (@{$items})
    {
	next if $item->{"Type"} ne "Item";
	my $id = $item->{"ID"};

	push(@gItemList,$id);
	$gItemInfo->{$id}->{"Name"} = $item->{"Name"};
	$gItemInfo->{$id}->{"AssetID"} = $item->{"AssetID"};
	$gItemInfo->{$id}->{"CreatorID"} = $item->{"CreatorID"};
	$gItemInfo->{$id}->{"ExtraData"} = to_json($item->{"ExtraData"}) if defined $item->{"ExtraData"};

	my $pid = $item->{"ParentID"};
	if (! defined $gFolderInfo->{$pid}->{"_LABEL"})
	{
	    $gFolderInfo->{$pid}->{"_LABEL"} = "parent_" . $gLabelCount++;
	}
	$gItemInfo->{$id}->{"ParentID"} = $gFolderInfo->{$pid}->{"_LABEL"};
    }
}

# -----------------------------------------------------------------
# NAME: CollectInventoryInformation
# -----------------------------------------------------------------
sub CollectInventoryInformation
{
    my $id;

    # initialize the information lists
    $gFolderInfo->{$gRootItemID}->{"Name"} = 'Name';
    $gFolderInfo->{$gRootItemID}->{"ContentType"} = 'application/vnd.ll.folder';
    $gFolderInfo->{$gRootItemID}->{"ParentID"} = 'UUID::Parse(UUID::Zero)';
    $gFolderInfo->{$gRootItemID}->{"_LABEL"} = 'RootID';

    push(@gFolderQueue,$gRootItemID);

    while (@gFolderQueue)
    {
	$id = shift(@gFolderQueue);
	push(@gFolderList,$id);

	my @flist = &GetSubFolders($id,$gAvatarUUID);
    }

    foreach $id (@gFolderList)
    {
	&GetFolderItems($id,$gAvatarUUID);
    }
}

# -----------------------------------------------------------------
# PrintFolders
# -----------------------------------------------------------------
sub PrintFolders
{
    print <<'EOS';

    $this->gFolders =
      array(
EOS

    foreach my $id (@gFolderList)
    {
	my $type = $gFolderInfo->{$id}->{"ContentType"};
	my $name = &CleanString($gFolderInfo->{$id}->{"Name"});
	my $pid =  $gFolderInfo->{$id}->{"ParentID"};
	my $uuid = $gFolderInfo->{$id}->{"_LABEL"};

	if ($id eq $gRootItemID)
	{

	    print "            array('ID' => \$RootID, 'ParentID' => $pid, 'Name' => \$Name, 'PreferredContentType' => '$type'),\n";
	}
	else
	{
	    print "            array('ID' => \$$uuid, 'ParentID' => \$$pid, 'Name' => '$name', 'PreferredContentType' => '$type'),\n";
	}
    }

    print <<'EOS';
	    );

EOS
}

# -----------------------------------------------------------------
# PrintItems
# -----------------------------------------------------------------
sub PrintItems
{
    print <<'EOS';
    $this->gItems =
      array(
EOS
    foreach my $id (@gItemList)
    {
	my $pid = $gItemInfo->{$id}->{"ParentID"};
	my $name = &CleanString($gItemInfo->{$id}->{"Name"});
	my $asset = $gItemInfo->{$id}->{"AssetID"};
	my $creator = $gItemInfo->{$id}->{"CreatorID"};
	my $edata = "";
	if (defined $gItemInfo->{$id}->{"ExtraData"})
	{
	    $edata = ", 'ExtraData' => '" . $gItemInfo->{$id}->{"ExtraData"} . "'";
	}
	    
	print "            array('ID' => UUID::Random(), 'ParentID' => \$$pid, 'Name' => '$name', 'AssetID' => '$asset', 'CreatorID' => '$creator' $edata),\n";
    }

    print <<'EOS';
	    );
    
EOS

}

# -----------------------------------------------------------------
# NAME: PrintAppearance
# wearables [[{'item':<uuid>,'asset':<uuid>}],[...]]
# textures [ <uuid>, ... ]
# visualparams [<integer>, ... ]
# attachments [{'point':<integer>, 'item':<uuid>, 'asset':<uuid>}, {...}, ...]
# -----------------------------------------------------------------
sub PrintAppearance
{
    print "    \$this->gAppearance = \n    array(\n";
    print "      'serial' => " . $gAvatarAppearance->{'serial'} . ",\n";
    print "      'height' => " . $gAvatarAppearance->{'height'} . ",\n";
    print "      'hipoffset' => " . $gAvatarAppearance->{'hipoffset'} . ",\n";

    # ---------------------------------------------
    # wearables
    # ---------------------------------------------
    print "      'wearables' => array(\n";
    my @wearables = @{$gAvatarAppearance->{'wearables'}};
    for (my $i = 0; $i <= $#wearables; $i++)
    {
        print "            array(";

        my @wearable = @{$wearables[$i]};
        for (my $j = 0; $j <= $#wearable; $j++)
        {
            my $item = $wearable[$j]->{'item'};
            my $asset = $wearable[$j]->{'asset'};
	    my $name = &CleanString($gItemInfo->{$item}->{"Name"});
	    my $pid = $gItemInfo->{$item}->{"ParentID"};
	    print "array( 'item' => \$this->FindItemID(\$$pid,'$name'), 'asset' => '$asset' )";
        }

        print "),\n";
    }
    print "        ),\n";

    # ---------------------------------------------
    # textures
    # ---------------------------------------------
    print "      'textures' => array(";
    my @textures = @{$gAvatarAppearance->{'textures'}};
    for (my $i = 0; $i <= $#textures; $i++)
    {
        print "'" . $textures[$i] . "', ";
    }
    print "),\n";

    # ---------------------------------------------
    # visual params
    # ---------------------------------------------
    print "      'visualparams' => array(";

    my @vparams = @{$gAvatarAppearance->{'visualparams'}};
    for (my $i = 0; $i <= $#vparams; $i++)
    {
        print $vparams[$i] . ", ";
    }
    print "),\n";

    # ---------------------------------------------
    # attachments
    # ---------------------------------------------
    print "      'attachments' => array(\n";
    my @attachments = @{$gAvatarAppearance->{'attachments'}};
    for (my $i = 0; $i <= $#attachments; $i++)
    {
        my $item = $attachments[$i]->{'item'};
        my $asset = $attachments[$i]->{'asset'};
        my $name = &CleanString($gItemInfo->{$item}->{"Name"});
        my $pid = $gItemInfo->{$item}->{"ParentID"};

        print "            array(";
        print "'point' => " . $attachments[$i]->{'point'} . ", ";
        print "'item' => \$this->FindItemID(\$$pid,'$name'), ";
        print "'asset' => '$asset'),\n";
    }
    print "      )\n";

    print "    );\n";
}

# -----------------------------------------------------------------
# PrintConstructor
# -----------------------------------------------------------------
sub PrintConstructor
{
    print <<'EOS';
  public function __construct($name,$userid)
  {
    /* folder information */
    $Name = $name;
    $RootID = $userid;

EOS

    my @labels = ();
    foreach my $id (@gFolderList)
    {
	my $lbl = $gFolderInfo->{$id}->{"_LABEL"};
	next if $lbl eq "RootID";

	push(@labels,$lbl);
    }

    foreach my $label (sort @labels)
    {
	print "    \$" . $label . " = UUID::Random();\n";
    }

    &PrintFolders;
    &PrintItems;
    &PrintAppearance;

    print <<'EOS'
  }

EOS
}

# -----------------------------------------------------------------
# NAME: CreateAvatarInventory
# -----------------------------------------------------------------
sub PrintAvatarInventory
{
    print <<"EOS";
<?php

class $gAvatarClassName implements IAvatarInventoryFolder
EOS
    print <<'EOS';
{
  private $gFolders;
  private $gItems;
  private $gAppearance;

  private function FindItemID($folderid,$iname)
  {
    foreach ($this->gItems as $ind => $item)
      {
	if ($item['ParentID'] == $folderid && $item['Name'] == $iname)
	  return $item['ID'];
      }

    log_message('error',"unable to locate item $iname in folder $folderid");
    return false;
  }

  private function FindAssetID($folderid,$iname)
  {
    foreach ($this->gItems as $ind => $item)
      {
	if ($item['ParentID'] == $folderid && $item['Name'] == $iname)
	  return $item['AssetID'];
      }
    
    log_message('error',"unable to locate asset item $iname in folder $folderid");
    return false;
  }

EOS

    &PrintConstructor;

    print <<'EOS';

  /* ----------------------------------------------------------------- */
  public function Folders()
  {
    return $this->gFolders;
  }

  /* ----------------------------------------------------------------- */
  public function Items()
  {
    return $this->gItems;
  }

  /* ----------------------------------------------------------------- */
  public function Appearance()
  {
    return $this->gAppearance;
  }

  /* ----------------------------------------------------------------- */
  public function Configure()
  {
  }
}
EOS
}

# -----------------------------------------------------------------
# NAME: Main
# -----------------------------------------------------------------
my $gOptions = {
    'c|class=s'          => \$gAvatarClassName,
    'i|uuid=s'          => \$gAvatarUUID,
    'n|name=s'		=> \$gAvatarName,
    'u|url=s' 		=> \$gSimianURL
};

my $gCmdinfo = Helper::CommandInfo->new(USAGE => "USAGE: $gCommand <options>");

$gCmdinfo->AddCommand('globals','options common to all commands');
$gCmdinfo->AddCommandParams('globals','-c|--class',' <string>','name of the avatar class to generate');
$gCmdinfo->AddCommandParams('globals','-i|--uuid',' <string>','avatars uuid');
$gCmdinfo->AddCommandParams('globals','-n|--name',' <string>','avatars full name');
$gCmdinfo->AddCommandParams('globals','-u|--url',' <string>','URL for simian grid functions');

sub Initialize
{
    if (! GetOptions(%{$gOptions}))
    {
	$gCmdinfo->DumpCommands('list',"Unknown option");
    }

    # must have the URL for simian
    $gSimianURL = $ENV{'SIMIAN'} unless defined $gSimianURL;
    if (! defined $gSimianURL)
    {
        $gCmdinfo->DumpCommands(undef,"No Simian URL specified");
    }

    $gSimian = Simian->new(URL => $gSimianURL);

    # now get the information from the avatar
    my $idvalue;
    my $idtype;
    $idvalue = $gAvatarName, $idtype = 'Name' if defined $gAvatarName;
    $idvalue = $gAvatarUUID, $idtype = 'UserID' if defined $gAvatarUUID;

    if (! defined $idvalue)
    {
        $gCmdinfo->DumpCommands(undef,"Avatar name not fully specified");
    }

    $gAvatarInfo = $gSimian->GetUser($idvalue,$idtype);
    $gAvatarAppearance = decode_json($gAvatarInfo->{"LLPackedAppearance"});

    if (! defined $gAvatarAppearance)
    {
        print STDERR "The specified avatar does not have a valid appearance\n";
        exit;
    }

    $gAvatarAppearance->{'serial'} = 1
        unless defined $gAvatarAppearance->{'serial'};

    $gAvatarAppearance->{'height'} = 1.5
        unless defined $gAvatarAppearance->{'height'};

    $gAvatarAppearance->{'hipoffset'} = -0.5
        unless defined $gAvatarAppearance->{'hipoffset'};

    $gRootItemID = $gAvatarInfo->{"UserID"};
    $gAvatarUUID = $gAvatarInfo->{"UserID"};

    open STDOUT, '>', "Avatar.$gAvatarClassName.php";
}

# -----------------------------------------------------------------
# NAME: Main
# -----------------------------------------------------------------
sub Main
{
    &Initialize();
    &CollectInventoryInformation();
    &PrintAvatarInventory();
}

&Main;



