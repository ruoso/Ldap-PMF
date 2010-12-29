package PainelUsuario::Model::LDAP;
use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_SERVER_DOWN);
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
  my $conn = Net::LDAP->new($host, %{$self->ldap_config})
    or die "$@";
  my $mesg = $conn->bind($self->ldap_config->{dn}, %{$self->ldap_config});
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
  if ($mesg->is_error) {
    if ($mesg->code == LDAP_SERVER_DOWN) {
      $self->ldap($self->_bind_ldap);
      return $self->buscar_dominios_auth();
    } else {
      croak 'LDAP error: ' . $mesg->error;
    }
  }
  return $mesg->sorted('o');
}

sub is_operador {
  my ($self, $user) = @_;
  return unless $user->has_attribute('memberof');
  my $roles = $user->get('memberof');
  $roles = [ $roles ] unless ref $roles eq 'ARRAY';
  return grep { $_ eq $self->role_operador } @{$roles};
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

my @update_fields =
  qw( cn sn givenname email matricula
      telephonenumber mobile );

sub update_self {
  my ($self, $user, $args) = @_;
  my %replace =
    map { $_ => $args->{$_} }
      grep { exists $args->{$_} &&
               $args->{$_} &&
                 $user->has_attribute($_) &&
                   $args->{$_} ne $user->get($_) }
        @update_fields;
  my %add =
    map { $_ => $args->{$_} }
      grep { exists $args->{$_} &&
               $args->{$_} &&
                 !$user->has_attribute($_) }
        @update_fields;
  my @delete =
    grep { !$args->{$_} &&
             $user->has_attribute($_) }
      @update_fields;

  return unless %replace or %add or @delete;

  my $mesg = $self->ldap->modify
    ( $user->dn,
      %replace ? (replace => \%replace) : (),
      %add ? (add => \%add) : (),
      @delete ? (delete => \@delete) : (),
    );
  die 'change-failed: '.$mesg->error if $mesg->is_error;
}

sub decompose_dn {
  my ($self, $dn) = @_;
  my $base = $self->ldap_config->{base};
  # remove o sufixo.
  my $prefix = substr($dn, 0, 0 - length($base));
  return [ map { (split /=/)[1] }
           split /,/, $prefix  ];
}

1;
