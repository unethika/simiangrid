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
        die "No Simian URL specified, please set SIMIAN environment variable";
    }

    $gSimian = Simian->new(URL => $gSimianURL);
}
    
# -----------------------------------------------------------------
# NAME: SlurpFile
# DESC: Read an entire file into a string
# -----------------------------------------------------------------
sub SlurpFile
{
    my $file = shift;

    local $/ = undef;
    open(FILE,(defined $file ? "<$file" : "<-")) || die "unable to open $file for reading; $!\n";
    my $string = <FILE>;
    close(FILE);

    return $string;
}

# -----------------------------------------------------------------
# NAME: Main
# -----------------------------------------------------------------
sub Main
{
    &CheckGlobals;

    my $rstring = &SlurpFile(shift @ARGV);
    my $request = decode_json($rstring);

    ## print to_json($request,{pretty => 1});
    my $results = $gSimian->_PostWebRequest($request);
    print (defined $results ? to_json($results,{pretty => 1}) : "request failed\n");
}

&Main;



