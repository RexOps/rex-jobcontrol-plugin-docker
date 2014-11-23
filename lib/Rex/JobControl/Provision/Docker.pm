#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

use strict;
use warnings;

package Rex::JobControl::Provision::Docker;

use Moo;
use YAML;
use namespace::clean;
use Rex::JobControl::Provision;
use Data::Dumper;

require Rex::Commands;
use Rex::Commands::Virtualization;

with 'Rex::JobControl::Provision::Base', 'Rex::JobControl::Plugin';

Rex::JobControl::Provision->register_type('docker');

has image     => ( is => 'ro' );
has host      => ( is => 'ro' );
has name      => ( is => 'ro' );
has command   => ( is => 'ro' );
has docker_id => ( is => 'ro' );
has volumes   => ( is => 'ro' );

sub create {
  my ($self) = @_;
  $self->project->app->log->debug(
    "Creating a docker container from image: " . $self->image );

  my $host_node = Rex::JobControl::Helper::Project::Node->new(
    node_id => $self->host,
    project => $self->project
  );

  my $auth = $self->get_auth_data($host_node);
  $self->project->app->ssh_pool->connect_to(
    ( $host_node->data->{ip} || $host_node->name ),
    %{$auth}, port => ( $host_node->data->{ssh_port} || 22 ) );

  Rex::Commands::set( virtualization => 'Docker' );

  my $id = vm
    create       => $self->name,
    image        => $self->image,
    command      => $self->command,
    share_folder => $self->volumes;

  $self->project->app->log->debug("Created new docker container: $id");

  return { docker_id => $id };
}

sub remove {
  my ($self) = @_;

  my $host_node = Rex::JobControl::Helper::Project::Node->new(
    node_id => $self->host,
    project => $self->project
  );

  my $auth = $self->get_auth_data($host_node);
  $self->project->app->ssh_pool->connect_to(
    ( $host_node->data->{ip} || $host_node->name ),
    %{$auth}, port => ( $host_node->data->{ssh_port} || 22 ) );

  Rex::Commands::set( virtualization => 'Docker' );

  eval { vm destroy => $self->docker_id; };
  vm delete => $self->docker_id;
}

sub get_auth_data {
  my ( $self, $node ) = @_;
  return $node->data->{data}->{docker}->{auth};
}

sub get_data {
  my ($self) = @_;

  my $host_node = Rex::JobControl::Helper::Project::Node->new(
    node_id => $self->host,
    project => $self->project
  );

  my $auth = $self->get_auth_data($host_node);
  $self->project->app->ssh_pool->connect_to(
    ( $host_node->data->{ip} || $host_node->name ),
    %{$auth}, port => ( $host_node->data->{ssh_port} || 22 ) );

  Rex::Commands::set( virtualization => 'Docker' );

  return vm info => $self->docker_id;
}

sub get_hosts {
  my ($self) = @_;
  return $self->project->get_nodes(
    sub {
      my ($file) = @_;
      $self->project->app->log->debug(
        "Reading $file to see if it is a docker host.");
      my $ref = YAML::LoadFile($file);
      if ( exists $ref->{data}
        && exists $ref->{data}->{docker_host}
        && $ref->{data}->{docker_host} )
      {
        return 1;
      }
      else {
        return 0;
      }
    }
  );
}

1;
