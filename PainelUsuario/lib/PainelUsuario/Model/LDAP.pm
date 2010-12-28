package PainelUsuario::Model::LDAP;
use Net::LDAP;
use Moose;
use Carp qw(croak);
use Digest::SHA qw(sha1_base64);
extends 'Catalyst::Model';

has ldap_config => (is => 'ro', required => 1);
has ldap => (is => 'rw', lazy => 1, builder => '_bind_ldap');
has dominios_dn => (is => 'ro', required => 1);
has role_operador => (is => 'ro', required => 1);

sub _bind_ldap {
  my $self = shift;
  my $host = $self->ldap_config->{host};
  my $conn = Net::LDAP->new($host, %{$self->{ldap_config}})
    or die "$@";
  my $mesg = $conn->bind;
  croak 'LDAP error: ' . $mesg->error if $mesg->is_error;
  return $conn;
}

sub buscar_dominios_auth {
  my $self = shift;
  my $mesg = $self->ldap->search
    ( base   => $self->dominios_dn,
      filter => "(&(objectClass=*))",
      scope  => 'one'
    );
  croak 'LDAP error: ' . $mesg->error if $mesg->is_error;
  return $mesg->sorted('o');
}

sub is_operador {
  my ($self, $user) = @_;
  return grep { $_ eq $self->role_operador } @{$user->memberof};
}

sub change_self_password {
  my ($self, $user, $curr_password, $new_password) = @_;
  my $encrypted = sha1_base64($new_password);
  $encrypted .= '=' while (length($encrypted) % 4);
  my $host = $self->ldap_config->{host};
  my $ldap = Net::LDAP->new($host, %{$self->{ldap_config}})
    or die "$@";
  my $mesg = $ldap->bind($user->dn, password => $curr_password);
  die 'bind-failed' if $mesg->is_error;
  $mesg = $ldap->modify($user->dn, replace => { userpassword => '{SHA}'.$encrypted });
  die 'change-failed' if $mesg->is_error;
}

1;
