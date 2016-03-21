#!/usr/bin/perl
use JSON;
use LWP::UserAgent;

my %packages;
my $arches   = $ENV{ARCHES}      // "amd64";
my $base_url = $ENV{VAGRANT_DIR} // "/vagrant/artifacts/";
$ENV{OUTPUT_REMOVED} = 1;

my @ARCHES = split( / /, $arches );

sub getarray {
    my $url = shift;
    my @res;
    open FILE, "<$url";
    @res = <FILE>;
    chomp(@res);
    return @res;
}

sub get_packages {
    my $repo = shift;
    my @packages;
    foreach my $arch (@ARCHES) {

        push( @packages,
            map { $_ .= " $repo $arch"; }
              getarray( $base_url . $repo . "/PKGLIST-" . $arch ) );

    }
    return @packages;
}

# Get all packages
my @packages;
foreach my $key ( getarray( $base_url . 'AVAILABLE_REPOSITORIES' ) ) {
    push( @packages, get_packages($key) );
}

# Create appropriate data used for later exports
my $packs;
my $vanilla_packages;
foreach my $p (@packages) {
    my @parts = split( / /, $p );
    $parts[0] =~ s/\~.*//g;
    push( @{ $vanilla_packages->{ $parts[1] } }, $parts[0] );
    $p = {
        "package"    => $parts[0],
        "repository" => $parts[1],
        "arch"       => $parts[2]
    };
}

# JSONP Metadata Generation and export
print "Generating JSONP metadata\n";
open FILE, ">$base_url/metadata.json";
print FILE "parsePackages(" . encode_json( \@packages ) . ")";
close FILE;

# Purge old package versions

foreach my $repo ( keys %{$vanilla_packages} ) {
    my @repo_packages = @{ $vanilla_packages->{$repo} };
    my @to_purge =
      `perl $base_url/../scripts/purge_old_versions.pl @repo_packages`;

    local $ENV{OUTPUT_DIR} = "$base_url/$repo";
    system("sabayon-createrepo-remove @to_purge");

}
