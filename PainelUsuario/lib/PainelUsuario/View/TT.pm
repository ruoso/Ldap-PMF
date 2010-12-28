package PainelUsuario::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config
  ( TEMPLATE_EXTENSION => '.tt',
    ENCODING  => 'UTF-8',
    render_die => 1,
);

=head1 NAME

PainelUsuario::View::TT - TT View for PainelUsuario

=head1 DESCRIPTION

TT View for PainelUsuario.

=head1 SEE ALSO

L<PainelUsuario>

=head1 AUTHOR

Daniel Ruoso,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
