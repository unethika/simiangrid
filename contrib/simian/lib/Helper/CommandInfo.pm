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

package Helper::CommandInfo;

use 5.010001;
use strict;
use warnings;

our $AUTOLOAD;
our $VERSION = sprintf "%s", '$Revision: 1.15 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Carp;

## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
## Command Handling
## XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
my %gAutoFields = (
    USAGE => undef,
    );

# -----------------------------------------------------------------
# NAME: AddCommand
# -----------------------------------------------------------------
sub AddCommand
{
    my $self = shift(@_);
    my ($cmd,$desc) = @_;
    
    $self->{_cmdinfo}->{$cmd} = $desc;
    $self->{_optinfo}->{$cmd} = {};
}

# -----------------------------------------------------------------
# NAME: AddCommandParams
# -----------------------------------------------------------------
sub AddCommandParams
{
    my $self = shift(@_);
    my ($cmd,$par,$val,$desc) = @_;

    $self->{_optinfo}->{$cmd}->{$par} = {};
    $self->{_optinfo}->{$cmd}->{$par}->{'value'} = $val;
    $self->{_optinfo}->{$cmd}->{$par}->{'description'} = $desc;
}

# -----------------------------------------------------------------
# NAME: DumpCommands
# -----------------------------------------------------------------
sub DumpCommands
{
    my $self = shift(@_);
    my ($cmd,$msg) = @_;
    
    print STDERR 'ERROR: ' . $msg . "\n" if defined $msg;
    print STDERR $self->{USAGE} . "\n" if defined $self->{USAGE};
    print STDERR "COMMON OPTIONS:\n";
    $self->_DumpOptions('globals');

    my @cmdlist = sort keys %{$self->{_cmdinfo}};
    exit(-1) if (scalar(@cmdlist) == 1);

    print STDERR "COMMANDS:\n";
    if (defined $cmd)
    {
        $self->_DumpCommand($cmd);
        exit(-1);
    }        

    foreach my $xcmd (@cmdlist)
    {
        $self->_DumpCommand($xcmd) unless $xcmd eq 'globals';
    }

    exit(-1);
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

    $self->{_cmdinfo} = {};
    $self->{_optinfo} = {};

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
# NAME: DumpCommand
# -----------------------------------------------------------------
sub _DumpCommand
{
    my $self = shift(@_);
    my ($cmd) = shift(@_);

    print STDERR "    $cmd\t" . $self->{_cmdinfo}->{$cmd} . "\n";
    $self->_DumpOptions($cmd);
}

# -----------------------------------------------------------------
# 
# -----------------------------------------------------------------
sub _DumpOptions
{
    my $self = shift(@_);
    my $cmd = shift(@_);

    foreach my $par (keys %{$self->{_optinfo}->{$cmd}})
    {
        my $val = $self->{_optinfo}->{$cmd}->{$par}->{'value'};
        my $desc = $self->{_optinfo}->{$cmd}->{$par}->{'description'};
        # print STDERR "\t$par ($val)\t-- $desc\n";
        print STDERR "\t\t$par$val : $desc\n";
    }
}

1;
__END__
