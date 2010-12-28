package PainelUsuario::Controller::Login;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/base') :PathPart('login') :CaptureArgs(0) {
}

sub login :Chained('base') :PathPart('') :Args(0) {
  my ($self, $c) = @_;
  if ($c->req->param('username')) {
    $c->get_auth_realm(PainelUsuario->config
                       ->{'Plugin::Authentication'}{default_realm})->store->user_basedn($c->req->param('dominio'));
    if ($c->authenticate({ username => $c->req->param('username'),
                           password => $c->req->param('password') })) {
      $c->res->redirect($c->uri_for_action('/home'));
    } else {
      $c->flash->{error} = 'access-denied';
    }
  }
}

__PACKAGE__->meta->make_immutable;

1;
