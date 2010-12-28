package PainelUsuario::Controller::Conta;
use 5.10.0;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use List::MoreUtils qw(all any);
BEGIN { extends 'Catalyst::Controller' }

sub base :Chained('/authbase') :PathPart('conta') :CaptureArgs(0) {}

sub index :Chained('base') :PathPart('') :Args(0) {
  my ($self, $c) = @_;
  if (my $mesg = $c->flash->{sucesso}) {
    $c->stash->{sucesso} = $mesg;
  }
  return unless $c->req->method eq 'POST';
  try {
    my %args =
      map { my $k = lc($_);
            $k =~ s/^ldap_//;
            ($k => $c->req->param($_))
          }
        grep { /^ldap_/ }
          keys %{$c->req->params};
    $c->model('LDAP')->update_self($c->user, \%args);
    $c->flash->{sucesso} = 'dados alterados';
    $c->res->redirect($c->uri_for_action('/conta/index'));
  } catch {
    $c->stash->{erro} = 'erro-desconhecido';
    $c->stash->{errolong} = $_;
  };
}

sub senha :Chained('base') :PathPart :Args(0) {
  my ($self, $c) = @_;
  if (any { $c->req->param($_) } qw(senha_atual senha1 senha2)) {
    unless (all { $c->req->param($_) } qw(senha_atual senha1 senha2)) {
      $c->stash->{erro} = 'all-fields';
      return;
    }
    unless ($c->req->param('senha1') eq $c->req->param('senha2')) {
      $c->stash->{erro} = 'didnt-match';
      return;
    }
    try {
      $c->model('LDAP')->change_self_password($c->user, $c->req->param('senha_atual'), $c->req->param('senha1'));
      $c->stash->{sucesso} = 'senha alterada';
    } catch {
      when (/^bind-failed/) {
        $c->stash->{erro} = 'senha-errada';
      }
      default {
        $c->stash->{erro} = 'erro-desconhecido';
        $c->stash->{errolong} = $_;
      }
    };
  }
}


__PACKAGE__->meta->make_immutable;

1;
