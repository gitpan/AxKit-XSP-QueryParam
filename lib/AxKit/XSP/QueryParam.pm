package AxKit::XSP::QueryParam;
# $Id: QueryParam.pm,v 1.1.1.1 2003/09/09 20:00:04 nachbaur Exp $
use Apache;
use Apache::Request;
use Apache::AxKit::Language::XSP::TaglibHelper;
sub parse_char  { Apache::AxKit::Language::XSP::TaglibHelper::parse_char(@_); }
sub parse_start { Apache::AxKit::Language::XSP::TaglibHelper::parse_start(@_); }
sub parse_end   { Apache::AxKit::Language::XSP::TaglibHelper::parse_end(@_); }

@EXPORT_TAGLIB = (
    'exists($name):isreally=paramexists',
    'remove($name)',
    'set($name,$value)',
    'get($name)',
    'if($name;$value):conditional=1:isreally=ifparam',
    'unless($name;$value):conditional=1:isreally=unlessparam',
    'if_regex($name,$value):conditional=1',
    'unless_regex($name,$value):conditional=1',
    'if_exists($name):conditional=1',
    'unless_exists($name):conditional=1',
    'enumerate():listtag=param-list:itemtag=param:forcearray=1',
);

@ISA = qw(Apache::AxKit::Language::XSP::TaglibHelper);
$NS = 'http://www.axkit.org/2002/XSP/QueryParam';
$VERSION = "0.01";

use strict;

## Taglib subs

sub if_exists
{
    my ( $name ) = @_;
    if (paramexists($name)) {
        return 1;
    }
    return undef;
}

sub unless_exists
{
    return undef if (if_exists(@_));
    return 1;
}

sub if_regex
{
    my ( $name, $value ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    if ($req->param($name) =~ /$value/) {
        return 1;
    }
    return undef;
}

sub unless_regex
{
    return undef if (if_regex(@_));
    return 1;
}

sub ifparam
{
    my ( $name, $value ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    if (defined($value)) {
        if ($req->param($name) =~ /^-?\d*\.?\d+$/ and $value =~ /^-?\d*\.?\d+$/) {
            if ($req->param($name) == $value) {
                return 1;
            }
        } else {
            if ($req->param($name) eq $value) {
                return 1;
            }
        }
    } else {
        if ($req->param($name)) {
            return 1;
        }
    }
    return undef;
}

sub unlessparam
{
    return undef if (ifparam(@_));
    return 1;
}

sub paramexists
{
    my ( $name ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    my @params = $req->param;
    foreach my $key (@params) {
        return 1 if ($key eq $name);
    }
    return 0;
}

sub remove
{
    my ( $name ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    my $table = $req->parms;
    $table->unset($name);
    return undef;
}

sub set
{
    my ( $name, $value ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    $req->param($name, $value);
    return undef;
}

sub get
{
    my ( $name ) = @_;
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    return $req->param($name);
}

sub enumerate
{
    my $r = Apache->request;
    my $req = Apache::Request->instance($r);
    my @tree = ();
    my @params = $req->param;
    foreach my $key (@params) {
        push @tree, {
            name  => $key,
            value => $req->param($key),
        };
    }
    return @tree;
}

1;

__END__

=head1 NAME

AxKit::XSP::QueryParam - Advanced parameter manipulation taglib

=head1 SYNOPSIS

Add the parm: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:param="http://www.axkit.org/2002/XSP/QueryParam"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::QueryParam

=head1 DESCRIPTION

AxKit::XSP::QueryParam is a taglib built around the Apache::Request
module that allows you to manipulate request parameters beyond simple
getting of parameter values.

=head1 Tag Reference

=head2 C<<param:get name="foo"/>>

Get a value from the given parameter.  The "name" attribute can be passed
as a child element for programattic access to parameter values.

=head2 C<<param:set name="foo" value="bar"/>>

Set a parameter value.  You can use child elements for both "name" and
"value".  This is very useful when you want to override the parameters
provided by the userr.

=head2 C<<param:remove name="foo"/>>

Remove a parameter.  Surprisingly enough, you can use child elements here
as well.  Are you beginning to notice a pattern?

=head2 C<<param:exists name="foo"/>>

Returns a boolean value representing whether the named parameter exists,
even if it has an empty or false value.  You can use child...oh, nevermind,
you get the idea.

=head2 C<<param:enumerate/>>

Returns an enumerated list of the parameter names present.  Now, you would
B<think> that you can use child elements here, but you can't!  Ha, fooled you!
This doesn't take any parameters, since it dumps the contents of the entire
parameter list to a structured element.  It outputs something like the
following:

  <param-list>
    <param id="1">
      <name>foo</name>
      <value>bar</name>
    </param>
    ...
  </param-list>

=head2 C<<param:if name="foo"></param:if>>

Executes the code contained within the block if the named parameter's value
is true.  You can optionally supply the attribute "value" if you want to evaluate
the value of a parameter against an exact string.

This tag, as well as all the other similar tags mentioned below can be changed to
"unless" to perform the exact opposite (ala Perl's "unless").  All options must
be supplied as attributes; child elements can not be used to supply these values.

=head2 C<<param:if-exists name="foo"></param:if-exists>>

Executes the code contained within the block if the named parameter exists
at all, regardless of it's value.

=head2 C<<param:if-regex name="foo" value="\w+"></param:if-regex>>

Executes the code contained within the block if the named parameter matches
the regular expression supplied in the "value" attribute.  The "value" attribute
is required.

=head1 AUTHOR

Michael A Nachbaur, mike@nachbaur.com

=head1 COPYRIGHT

Copyright (c) 2002-2003 Michael A Nachbaur. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<AxKit>, L<Apache::Request>

=cut
