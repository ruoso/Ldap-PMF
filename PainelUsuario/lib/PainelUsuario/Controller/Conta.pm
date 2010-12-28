package PainelUsuario::Controller::Conta;
use 5.10.0;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use List::MoreUtils qw(all any);
BEGIN { extends 'Catalyst::Controller' }

sub base :Chained('/authbase') :PathPart('conta') :CaptureArgs(0) {}

sub index :Chained('base') :PathPart('') :Args(0) {}

sub update :Chained('base') :PathPart :Args(0) {
  my ($self, $c) = @_;
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
      when ('bind-failed') {
        $c->stash->{erro} = 'senha-errada';
      }
      default {
        $c->stash->{erro} = 'erro-desconhecido';
      }
    };
  }
}


__PACKAGE__->meta->make_immutable;

1;
