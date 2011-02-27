package Plack::Middleware::Precompressed;
BEGIN {
  $Plack::Middleware::Precompressed::VERSION = '1.004';
}
use strict;
use parent 'Plack::Middleware';

# ABSTRACT: serve pre-gzipped content to compression-enabled clients

use Plack::Util::Accessor qw( match );
use Plack::MIME ();
use Plack::Util ();

sub call {
	my $self = shift;
	my ( $env ) = @_;

	my $encoding;
	my $path = $env->{'PATH_INFO'};
	my $have_match = $self->match ? $path =~ $self->match : 1;

	if ( $have_match ) {
		( $encoding ) =
			grep { $_ eq 'gzip' or $_ eq 'x-gzip' }
			map  { s!\s+!!g; split /,/, lc }
			grep { defined }
			$env->{'HTTP_ACCEPT_ENCODING'};
	}

	my $res = do {
		local $env->{'PATH_INFO'} = "$path.gz" if $encoding;
		$self->app->( $env );
	};

	return $res unless $have_match;

	my $is_fail;
	my $final_res = Plack::Util::response_cb( $res, sub {
		my $res = shift;
		$is_fail = $res->[0] != 200;
		return if $is_fail;
		Plack::Util::header_push( $res->[1], 'Vary', 'Accept-Encoding' );
		if ( $encoding ) {
			my $mime = Plack::MIME->mime_type( $path );
			Plack::Util::header_set( $res->[1], 'Content-Type', $mime ) if $mime;
			Plack::Util::header_push( $res->[1], 'Content-Encoding', $encoding );
		}
		return;
	} );

	return $is_fail ? $self->app->( $env ) : $final_res;
}

1;



=pod

=head1 NAME

Plack::Middleware::Precompressed - serve pre-gzipped content to compression-enabled clients

=head1 VERSION

version 1.004

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable 'Plack::Middleware::Precompressed', match => qr!\.js\z!;
      $handler;
  };

=head1 DESCRIPTION

Plack::Middleware::Precompressed is an alternative (or rather, complement) to
middlewares like L<Deflater|Plack::Middleware::Deflater>, which will compress
response bodies on the fly. For dynamic resources, that behaviour is necessary,
but for static resources it is a waste: identical entities will be compressed
over and over. Instead, I<Precompressed> allows you to compress static
resources once, e.g. as part of your build process, and then serve the
compressed resource in place of the uncompressed one for compression-enabled
clients.

To do so, it appends a C<.gz> suffix to the request URI and tries to serve
that. If that fails, it will try again with the unmodified URI.

B<Note>: this means requests for resources that are not pre-compressed will
always be dispatched I<twice>. You are are advised to use either the C<match>
parameter or L<the Conditional middleware|Plack::Middleware::Conditional> or
something of the sort, to prevent requests from passing through this middleware
unnecessarily.

=head1 CONFIGURATION OPTIONS

=over 4

=item match

Specifies a regex that must match the request URI to trigger the middleware.

=back

=head1 SEE ALSO

L<Plack::Middleware::Deflater>

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

