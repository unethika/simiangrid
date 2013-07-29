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

package Simian;

use 5.010001;
use strict;
use warnings;

our $AUTOLOAD;
our $VERSION = sprintf "%s", '$Revision: 1.0 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Carp;

use JSON;
use MIME::Base64;
use LWP::UserAgent;

## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
## Simian interface functions
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
my %gAutoFields = (
    URL => undef,
    CAP => undef,
    );

# -----------------------------------------------------------------
# NAME: GetAsset
# -----------------------------------------------------------------
sub GetAsset()
{
    my $self = shift;
    my ($id) = @_;

    # Create a request
    my $params = { 'RequestMethod' => 'xGetAsset', 'ID' => $id };
    my $results = $self->_PostWebRequest($params);
    return defined($results) ? decode_base64($results->{"EncodedData"}) : undef;
}

# -----------------------------------------------------------------
# NAME: GetAssetMetadata
# -----------------------------------------------------------------
sub GetAssetMetadata()
{
    my $self = shift;
    my ($id) = @_;

    # Create a request
    my $params = { 'RequestMethod' => 'xGetAssetMetadata', 'ID' => $id };
    my $results = $self->_PostWebRequest($params);
    return $results;
}

# -----------------------------------------------------------------
# NAME: AddAsset
# -----------------------------------------------------------------
sub AddAsset()
{
    my $self = shift;
    my ($creatorID, $contenttype, $content) = @_;

    # Create a request
    my $params = {
        'RequestMethod' => 'xAddAsset',
        'EncodedData' => encode_base64($content),
        'ContentType' => $contenttype,
        'CreatorID' => $creatorID
    };
    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{'AssetID'} : undef;
}

# -----------------------------------------------------------------
# NAME: GetUserList
# -----------------------------------------------------------------
sub GetUserList()
{
    my $self = shift;
    my ($nameq) = @_;

    # Create a request
    my $params = { 'RequestMethod' => 'GetUsers', 'NameQuery' => $nameq };
    my $results = $self->_PostWebRequest($params);
    return $results->{"Users"};
}

# -----------------------------------------------------------------
# NAME: GetUser
# -----------------------------------------------------------------
sub GetUser()
{
    my $self = shift;
    my ($idvalue, $idtype) = @_;

    $idtype = 'Name' unless defined $idtype;

    # Create a request
    my $params = { 'RequestMethod' => 'GetUser', $idtype => $idvalue };
    my $results = $self->_PostWebRequest($params);
    return $results->{"User"};
}

# -----------------------------------------------------------------
# NAME: AddUserData($uuid,$key,$val)
# -----------------------------------------------------------------
sub AddUserData()
{
    my $self = shift;
    my ($uuid,$key,$val) = @_;

    # Create a request
    my $params = { 'RequestMethod' => 'AddUserData', 'UserID' => $uuid, $key => $val };
    my $results = $self->_PostWebRequest($params);
    return defined($results);
}

# -----------------------------------------------------------------
# NAME: RemoveUserData($uuid,$key)
# -----------------------------------------------------------------
sub RemoveUserData()
{
    my $self = shift;
    my ($uuid,$key) = @_;

    # Create a request
    my $params = { 'RequestMethod' => 'RemoveUserData', 'UserID' => $uuid, 'Key' => $key };
    my $results = $self->_PostWebRequest($params);
    return defined($results);
}

# -----------------------------------------------------------------
# NAME: RemoveUser
# -----------------------------------------------------------------
sub RemoveUser
{
    my $self = shift;
    my ($uuid) = @_;

    my $params = {
        'RequestMethod' => 'RemoveUser',
        'UserID' => $uuid
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results);
}

# -----------------------------------------------------------------
# NAME: RemoveInventoryNode
# -----------------------------------------------------------------
sub RemoveInventoryNode
{
    my $self = shift;
    my ($owner,$item) = @_;

    my $params = {
        'RequestMethod' => 'RemoveInventoryNode',
        'ItemID' => $item,
        'OwnerID' => $owner
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results);
}

# -----------------------------------------------------------------
# NAME: GetInventoryNode
# -----------------------------------------------------------------
sub GetInventoryNode()
{
    my $self = shift;
    my ($itemID,$ownerID,$iparams) = @_;

    my $incfolders = (defined $iparams->{'IncludeFolders'} ? $iparams->{'IncludeFolders'} : 0);
    my $incitems = (defined $iparams->{'IncludeItems'} ? $iparams->{'IncludeItems'} : 0);
    my $childonly = (defined $iparams->{'ChildrenOnly'} ? $iparams->{'ChildrenOnly'} : 0);

    my $params = {
        'RequestMethod' => 'GetInventoryNode',
        'ItemID' => $itemID,
        'OwnerID' => $ownerID,
        'IncludeFolders' => $incfolders,
        'IncludeItems' => $incitems,
        'ChildrenOnly' => $childonly
    };

    # Check the outcome of the response
    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{'Items'} : undef;
}

# -----------------------------------------------------------------
# NAME: AddInventoryFolder
# -----------------------------------------------------------------
sub AddInventoryFolder
{
    my $self = shift;
    my ($parentID,$ownerID,$name,$type) = @_;

    my $params = {
        'RequestMethod' => 'AddInventoryFolder',
        'ParentID' => $parentID,
        'OwnerID' => $ownerID,
        'Name' => $name
    };

    $params->{'ContentType'} = $type if defined $type;

    # Check the outcome of the response
    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{'FolderID'} : undef;
}

# -----------------------------------------------------------------
# NAME: AddInventoryItem
# -----------------------------------------------------------------
sub AddInventoryItem
{
    my $self = shift;
    my ($parentID,$ownerID,$name,$assetID,$desc) = @_;

    my $params = {
        'RequestMethod' => 'AddInventoryItem',
        'ParentID' => $parentID,
        'OwnerID' => $ownerID,
        'AssetID' => $assetID,
        'Name' => $name
    };

    $params->{'Description'} = $desc if defined $desc;

    # Check the outcome of the response
    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{'ItemID'} : undef;
}

# -----------------------------------------------------------------
# NAME: AddUser
# -----------------------------------------------------------------
sub AddUser
{
    my $self = shift;
    my ($uuid,$name,$email,$access) = @_;
    
    $access = 0 unless defined $access;

    my $params = {
        'RequestMethod' => 'AddUser',
        'Name' => $name,
        'Email' => $email,
        'UserID' => $uuid,
        'AccessLevel' => $access
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $uuid : undef;
}

# -----------------------------------------------------------------
# NAME: AddIdentity($uuid,$type,$identifier,$credential)
# -----------------------------------------------------------------
sub AddIdentity
{
    my $self = shift;
    my ($uuid,$type,$identifier,$credential) = @_;

    my $params = {
        'RequestMethod' => 'AddIdentity',
        'Identifier' => $identifier,
        'Credential' => $credential,
        'Type' => $type,
        'UserID' => $uuid
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results);
}

# -----------------------------------------------------------------
# NAME: GetIdentities(uuid)
# -----------------------------------------------------------------
sub GetIdentities
{
    my $self = shift;
    my ($uuid) = @_;

    my $params = {
        'RequestMethod' => 'GetIdentities',
        'UserID' => $uuid
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Identities"} : undef;
}

# -----------------------------------------------------------------
# NAME: CreateAvatar($uuid,$avtype)
# -----------------------------------------------------------------
sub CreateAvatar
{
    my $self = shift;
    my ($uuid,$avtype) = @_;

    my $params = {
        'RequestMethod' => 'AddInventory',
        'AvatarType' => $avtype,
        'OwnerID' => $uuid
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"FolderID"} : undef;
}

# -----------------------------------------------------------------
# NAME: GetSessionList()
# -----------------------------------------------------------------
sub GetSessionList
{
    my $self = shift;
    
    my $params = {
        'RequestMethod' => 'GetSessions'
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Sessions"} : undef;
}

# -----------------------------------------------------------------
# NAME: GetSession($idvalue,$idtype) -- type can be UserID or SessionID
# -----------------------------------------------------------------
sub GetSession
{
    my $self = shift;
    my ($idvalue, $idtype) = @_;

    $idtype = 'SessionID' unless defined $idtype;

    # Create a request
    my $params = { 'RequestMethod' => 'GetSession', $idtype => $idvalue };
    my $results = $self->_PostWebRequest($params);
    return $results;
}

# -----------------------------------------------------------------
# NAME: RemoveSession($idvalue,$idtype) -- type can be UserID or SessionID
# -----------------------------------------------------------------
sub RemoveSession
{
    my $self = shift;
    my ($idvalue, $idtype) = @_;

    $idtype = 'SessionID' unless defined $idtype;

    # Create a request
    my $params = { 'RequestMethod' => 'RemoveSession', $idtype => $idvalue };
    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: GetSceneList($name,$enabled)
# -----------------------------------------------------------------
sub GetSceneList
{
    my $self = shift;
    my ($name,$enabled) = @_;
    $enabled = 0 unless defined $enabled;
    
    my $params = {
        'RequestMethod' => 'GetScenes',
        'NameQuery' => $name,
        'Enabled' => $enabled
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Scenes"} : undef;
}

# -----------------------------------------------------------------
# NAME: GetScene($value, $type)
# -----------------------------------------------------------------
sub GetScene
{
    my $self = shift;
    my ($idvalue, $idtype) = @_;

    $idtype = 'Name' unless defined $idtype;
    
    my $params = {
        'RequestMethod' => 'GetScene',
        $idtype => $idvalue
    };

    my $results = $self->_PostWebRequest($params);
    delete $results->{'Success'} if defined $results->{'Success'};

    return $results;
}

# -----------------------------------------------------------------
# NAME: EnableScene($value, $type, $enabled)
# -----------------------------------------------------------------
sub EnableScene
{
    my $self = shift;
    my ($idvalue, $idtype, $enabled) = @_;
    
    $idtype = 'Name' unless defined $idtype;
    $enabled = 1 unless defined $enabled;

    my $params = {
        'RequestMethod' => 'EnableScene',
        $idtype => $idvalue,
        'Enabled' => $enabled
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: AddScene($uuid,$name,$minpos,$maxpos,$addr,$enabled)
# -----------------------------------------------------------------
sub AddScene
{
    my $self = shift;
    my ($uuid,$name,$minp,$maxp,$addr,$enabled) = @_;
    
    $addr = "" unless defined $addr;
    $enabled = 0 unless defined $enabled;

    my $params = {
        'RequestMethod' => 'AddScene',
        'SceneID' => $uuid,
        'Name' => $name,
        'MinPosition' => sprintf("<%d,%d,%d>",$minp->[0],$minp->[1],$minp->[2]),
        'MaxPosition' => sprintf("<%d,%d,%d>",$maxp->[0],$maxp->[1],$maxp->[2]),
        'Address' => $addr,
        'Enabled' => $enabled
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: RemoveSceneByID($uuid)
# -----------------------------------------------------------------
sub RemoveScene
{
    my $self = shift;
    my ($idvalue, $idtype) = @_;

    $idtype = 'Name' unless defined $idtype;
    
    my $params = {
        'RequestMethod' => 'RemoveScene',
        $idtype => $idvalue
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: RemoveSceneByName($name)
# -----------------------------------------------------------------
sub RemoveSceneByName
{
    my $self = shift;
    my ($name) = @_;
    
    my $params = {
        'RequestMethod' => 'RemoveScene',
        'Name' => $name
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: AddActor(actorID,actorType,address,port)
# -----------------------------------------------------------------
sub AddActor
{
    my $self = shift;
    my ($actor,$type,$addr,$port) = @_;
    
    my $params = {
        'RequestMethod' => 'AddActor',
        'ActorID' => $actor,
        'ActorType' => $type,
        'Address' => $addr,
        'Port' => $port
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: RemoveActor(actorID)
# -----------------------------------------------------------------
sub RemoveActor
{
    my $self = shift;
    my ($actor) = @_;
    
    my $params = {
        'RequestMethod' => 'RemoveActor',
        'ActorID' => $actor
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: AddQuark(actorID,xpos,ypos)
# -----------------------------------------------------------------
sub AddQuark
{
    my $self = shift;
    my ($actor,$xpos,$ypos) = @_;
    
    my $params = {
        'RequestMethod' => 'AddQuark',
        'ActorID' => $actor,
        'LocX' => $xpos,
        'LocY' => $ypos
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: RemoveQuark(actorID,xpos,ypos)
# -----------------------------------------------------------------
sub RemoveQuark
{
    my $self = shift;
    my ($actor,$xpos,$ypos) = @_;
    
    my $params = {
        'RequestMethod' => 'RemoveQuark',
        'ActorID' => $actor,
        'LocX' => $xpos,
        'LocY' => $ypos
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: GetQuark(actorType,xpos,ypos)
# -----------------------------------------------------------------
sub GetQuark
{
    my $self = shift;
    my ($type,$xpos,$ypos) = @_;
    
    my $params = {
        'RequestMethod' => 'GetQuark',
        'ActorType' => $type,
        'LocX' => $xpos,
        'LocY' => $ypos
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Actors"} : undef;
}

# -----------------------------------------------------------------
# NAME: GetEndpoint(syncServerID)
# -----------------------------------------------------------------
sub GetEndpoint
{
    my $self = shift;
    my ($syncServerID) = @_;
    
    my $params = {
        'RequestMethod' => 'GetEndpoint',
        'SyncServerID' => $syncServerID,
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results : undef;
}

# -----------------------------------------------------------------
# NAME: GetQuarks(actorType,xpos,ypos)
# -----------------------------------------------------------------
sub GetQuarks
{
    my $self = shift;
    my ($xmin,$ymin,$xmax,$ymax) = @_;
    
    my $params = {
        'RequestMethod' => 'GetQuarks'
    };

    $params->{'MinX'} = $xmin if defined $xmin;
    $params->{'MinY'} = $ymin if defined $ymin;
    $params->{'MaxX'} = $xmax if defined $xmax;
    $params->{'MaxY'} = $ymax if defined $ymax;

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Quarks"} : undef;
}

# -----------------------------------------------------------------
# NAME: AddCapability($ownerid,$resource,$expire)
# -----------------------------------------------------------------
sub AddCapability
{
    my $self = shift;
    my ($ownerid,$resource,$expire) = @_;
    
    my $params = {
        'RequestMethod' => 'AddCapability',
        'OwnerID' => $ownerid,
        'Resource' => $resource,
        'Expiration' => $expire
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"CapabilityID"} : undef;
}

# -----------------------------------------------------------------
# NAME: GetCapability($capid)
# -----------------------------------------------------------------
sub GetCapability
{
    my $self = shift;
    my ($capid) = @_;
    
    my $params = {
        'RequestMethod' => 'GetCapability',
        'CapabilityID' => $capid
    };

    my $results = $self->_PostWebRequest($params);
    return $results;
}

# -----------------------------------------------------------------
# NAME: RemoveCapability($capid)
# -----------------------------------------------------------------
sub RemoveCapability
{
    my $self = shift;
    my ($capid) = @_;
    
    my $params = {
        'RequestMethod' => 'RemoveCapability',
        'CapabilityID' => $capid
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: GetUserCapabilities
# -----------------------------------------------------------------
sub GetUserCapabilities
{
    my $self = shift;
    my ($ownerid) = @_;
    
    my $params = {
        'RequestMethod' => 'GetUserCapabilities',
        'OwnerID' => $ownerid
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Capabilities"} : undef;
}

# -----------------------------------------------------------------
# NAME: RemoveUserCapabilities
# -----------------------------------------------------------------
sub RemoveUserCapabilities
{
    my $self = shift;
    my ($ownerid) = @_;
    
    my $params = {
        'RequestMethod' => 'RemoveUserCapabilities',
        'OwnerID' => $ownerid
    };

    my $results = $self->_PostWebRequest($params);
    return defined($results) ? $results->{"Success"} : undef;
}

# -----------------------------------------------------------------
# NAME: new
# DESC: Constructor for the object, attributes listed in gAutoFields
# can be initialized here.
# -----------------------------------------------------------------
sub new {
    my $proto = shift;
    my $parms = ($#_ == 0) ? { %{ (shift) } } : { @_ };

    my $class = ref($proto) || $proto;
    my $self = { };

    bless $self, $class;

    # Copy the parameters into the object
    $self->{_permitted} = \%gAutoFields;

    # Set the initial values for all the parameters
    foreach my $key (keys %{$self->{_permitted}}) {
        $self->{$key} = $parms->{$key} || $self->{_permitted}->{$key};
    }

    carp 'Simian URL undefined' unless defined $self->{URL};

    $self->{_ua}  = LWP::UserAgent->new;
    $self->{_ua}->agent("MyApp/0.1 ");

    return $self;
}

# -----------------------------------------------------------------
# The AUTOLOADer will set up accessor methods for the following fields:
# CHANNEL, SERVICE, INSTANCE, and BODY. For now META is included here
# but we might want to handle it differently.
# -----------------------------------------------------------------
sub AUTOLOAD {
    my $self = shift;

    my $fullname = $AUTOLOAD;
    return if $fullname =~ /::DESTROY$/; # just ignore this

    # unpack the function name to get the operation & variable
    my ($pack,$func,$name) = ($fullname =~ /^(.*)::(Get|Set)(\w+)$/);
    unless ($pack && $func && $name) {
        carp "Undefined method; $fullname\n";
        return undef;
    }

    # verify that this is a reasonable variable, uppercase check only
    $name =~ tr/a-z/A-Z/;
    unless (exists $self->{_permitted}->{$name}) {
        carp "Unknown method; $fullname\n";
        return undef;
    }

    # handle the operation
    $self->{$name} = shift
        if ($func eq 'Set');

    return $self->{$name};
}

# -----------------------------------------------------------------
# NAME: _PostWebRequest
# -----------------------------------------------------------------
sub _PostWebRequest()
{
    my $self = shift;
    my ($params) = @_;

    # Create a request
    $params->{'cap'} = $self->{CAP} if defined $self->{CAP};
    my $res = $self->{_ua}->post($self->{URL},$params);

    # Check the outcome of the response
    if (! $res->is_success)
    {
	carp $res->status_line . "\n";
	return;
    }

    # Process the folders in the result
    # print STDERR "result=" . $res->content . "\n";

    my $results = decode_json($res->content);
    carp "JSON decode failed; $!\n" unless defined($results);

    if (! $results->{"Success"})
    {
        my $msg = $results->{"Message"} || "unknown error";
        carp "Invocation failed; $msg\n";
    }

    return $results;
}

# -----------------------------------------------------------------
# NAME: _GetWebRequest
# -----------------------------------------------------------------
sub _GetWebRequest()
{
    my $self = shift;
    my ($params) = @_;

    # Create a request
    $params->{'cap'} = $self->{CAP} if defined $self->{CAP};
    my $url = URI->new($self->{URL});
    $url->query_form($params);

    # print STDERR "url=" . $url . "\n";

    my $res = $self->{_ua}->get($url);

    # Check the outcome of the response
    if (! $res->is_success)
    {
	carp $res->status_line . "\n";
	return;
    }

    return $res->content;
}

1;
__END__
