package PainelUsuario::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub base :Chained('/') :PathPart('') :CaptureArgs(0) {
}

sub default :Chained('base') :PathPart('') :Args {
  my ( $self, $c ) = @_;
  $c->response->body( 'Page not found' );
  $c->response->status(404);
}

sub authbase :Chained('base') :PathPart('') :CaptureArgs(0) {
  my ($self, $c) = @_;
  $c->get_auth_realm
    (PainelUsuario->config->{'Plugin::Authentication'}{default_realm})
      ->store->user_basedn($c->session->{dominio});
  unless ($c->user) {
    $c->res->redirect($c->uri_for_action('/login/login'));
    $c->detach;
  }
}

sub home :Chained('authbase') :PathPart('') :Args(0) {
  my ($self, $c) = @_;
  unless ($c->model('LDAP')->is_operador($c->user)) {
    $c->res->redirect($c->uri_for_action('/conta/index'));
  }
}

sub logout :Chained('authbase') :PathPart :Args(0) {
  my ($self, $c) = @_;
  $c->logout;
  $c->res->redirect($c->uri_for_action('/login/login'));
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
