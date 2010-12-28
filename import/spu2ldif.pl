use 5.10.0;
use strict;
use warnings;
use Text::CSV;

my $csv = Text::CSV->new();
open my $fh, "<:encoding(utf8)", "input.csv"
  or die $!;

binmode STDOUT, ':utf8';

my %dn;

my @foradeordem;
while (my $row = $csv->getline($fh)) {
  processa_linha($row);
}
while (my @outros = @foradeordem) {
  @foradeordem = ();
  foreach my $row (@outros) {
    processa_linha($row);
  }
}

sub processa_linha {
  my $row = shift;
  my ($id_este, $id_pai, $sigla, $nome, $resp, $s1, $s2, $id_ug) = @$row;
  my (%entry, $dn_pai, $rdn_attr);

  if ($id_pai == $id_este) {
    $dn_pai = 'dc=adm,dc=diretorio,dc=fortaleza,dc=ce,dc=gov,dc=br';
  } elsif (exists $dn{$id_pai}) {
    $dn_pai = $dn{$id_pai};
  } else {
    push @foradeordem, $row;
    return;
  }

  if ($id_este == $id_ug) {
    $entry{objectClass} = 'unidadeGestao';
    $rdn_attr = 'o';
  } else {
    $entry{objectClass} = 'unidadeAdminstrativa';
    $rdn_attr = 'ou';
  }

  $entry{$rdn_attr} = $sigla;
  $entry{description} = $nome;
  $entry{idEstruturaSPU} = $id_este;
  $entry{dn} = "${rdn_attr}=${sigla},${dn_pai}";
  $dn{$id_este} = $entry{dn};

  output_ldif(\%entry);

}

sub output_ldif {
  my $input = shift;
  my %entry = %$input;
  my $dn = delete $entry{dn};
  print "dn: ${dn}\n";
  print
    join "\n",
      map { join ": ", $_, $entry{$_} }
        keys %entry;
  print "\n\n";
}
