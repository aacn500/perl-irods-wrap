package WTSI::NPG::iRODS::MetaLister;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

our $VERSION = '';

extends 'WTSI::NPG::iRODS::Communicator';

has '+executable' => (default => 'baton-list');

around [qw(list_collection_meta list_object_meta)] => sub {
  my ($orig, $self, @args) = @_;

  unless ($self->started) {
    $self->logconfess('Attempted to use a WTSI::NPG::iRODS::MetaLister ',
                      'without starting it');
  }

  return $self->$orig(@args);
};

sub list_collection_meta {
  my ($self, $collection) = @_;

  defined $collection or
    $self->logconfess('A defined collection argument is required');

  $collection =~ m{^/}msx or
    $self->logconfess("An absolute object path argument is required: ",
                      "received '$collection'");

  $collection = File::Spec->canonpath($collection);

  my $spec = {collection => $collection};

  return $self->_list_path_meta($spec);
}

sub list_object_meta {
  my ($self, $object) = @_;

  defined $object or
    $self->logconfess('A defined object argument is required');

  $object =~ m{^/}msx or
    $self->logconfess("An absolute object path argument is required: ",
                      "received '$object'");

  my ($volume, $collection, $data_name) = File::Spec->splitpath($object);
  $collection = File::Spec->canonpath($collection);

  $data_name or $self->logconfess("An object path argument is required: ",
                                  "received '$object'");

  my $spec = {collection  => $collection,
              data_object => $data_name};

  return $self->_list_path_meta($spec);
}

sub _list_path_meta {
  my ($self, $spec) = @_;

  defined $spec or
    $self->logconfess('A defined JSON spec argument is required');

  my $response = $self->communicate($spec);
  $self->validate_response($response);
  $self->report_error($response);

  my @avus;
  if (ref $response->{avus} eq 'ARRAY') {
    @avus = @{$response->{avus}};
  }
  else {
    $self->logconfess('The returned path spec did not have an "avus" key ',
                      'with an ArrayRef value: ', $self->encode($response));
  }

  return @avus;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME

WTSI::NPG::iRODS::MetaLister

=head1 DESCRIPTION

A client that lists iRODS metadata as JSON.

=head1 AUTHOR

Keith James <kdj@sanger.ac.uk>

=head1 COPYRIGHT AND DISCLAIMER

Copyright (C) 2013, 2014, 2015 Genome Research Limited. All Rights
Reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the Perl Artistic License or the GNU General
Public License as published by the Free Software Foundation, either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
