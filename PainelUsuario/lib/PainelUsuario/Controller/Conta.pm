package PainelUsuario::Controller::Conta;
use Moose;
use namespace::autoclean;
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
    unless (all { $c->req->param($_) } qw(senha_autal senha1 senha2)) {
      $c->stash->{erro} = 'all-fields';
      return;
    }
  }
}


__PACKAGE__->meta->make_immutable;

1;
