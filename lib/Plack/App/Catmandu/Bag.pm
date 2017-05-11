package Plack::App::Catmandu::Bag;

use Catmandu::Sane;

our $VERSION = '0.01';

use parent 'Plack::Component';
use Catmandu;
use Router::Simple;
use JSON qw(encode_json);
use namespace::clean;

sub bag {
    my ($self) = @_; $self->{_bag} ||= $self->_build_bag;
}

sub router {
    my ($self) = @_; $self->{_router} ||= $self->_build_router;
}

sub _build_bag {
    my ($self) = @_;
    Catmandu->store($self->{store})->bag($self->{bag});
}

sub _build_router {
    my ($self) = @_;
    my $router = Router::Simple->new;
    if ($self->bag->does('Catmandu::Plugin::Versioning')) {
        $router->connect('/{id}/versions', {action => 'version_list'}, {method => 'GET'});
        $router->connect('/{id}/versions/{version}', {action => 'version_show'}, {method => 'GET'});
    }
    $router->connect('/', {action => 'list'}, {method => 'GET'});
    $router->connect('/{id}', {action => 'show'}, {method => 'GET'});
    $router;
}

sub list {
    my ($self, $params) = @_;
    my $start = $params->{start} // 0;
    my $limit = $params->{limit} // 10;
    $self->ok($self->bag->slice($start, $limit)->to_array);
}

sub show {
    my ($self, $params) = @_;
    if (my $data = $self->bag->get($params->{id})) {
        $self->ok($data);
    } else {
        $self->not_found;
    }
}

sub version_list {
    my ($self, $params) = @_;
    if (my $data = $self->bag->get_history($params->{id})) {
        $self->ok($data);
    } else {
        $self->not_found;
    }
}

sub version_show {
    my ($self, $params) = @_;
    if (my $data = $self->bag->get_version($params->{id}, $params->{version})) {
        $self->ok($data);
    } else {
        $self->not_found;
    }
}

sub ok {
    my ($self, $data) = @_;
    my $res = {data => $data};
    [
        '200',
        ['Content-Type' => 'application/vnd.api+json'],
        [encode_json($res)],
    ];
}

sub method_not_allowed {
    ['405', ['Content-Type' => 'text/plain'], ['Method Not Allowed']];
}

sub not_found {
    ['404', ['Content-Type' => 'text/plain'], ['Not Found']];
}

sub call {
    my ($self, $env) = @_;
    my $router = $self->router;

    if (my $params = $router->match($env)) {
        my $action = $params->{action};
        $self->$action($params);
    } elsif ($router->method_not_allowed) {
        $self->method_not_allowed;
    } else {
        $self->not_found;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::App::Catmandu::Bag - Blah blah blah

=head1 SYNOPSIS

  use Plack::App::Catmandu;

=head1 DESCRIPTION

Plack::App::Catmandu is

=head1 AUTHOR

Nicolas Steenlant E<lt>nicolas.steenlant@ugent.beE<gt>

=head1 COPYRIGHT

Copyright 2017- Nicolas Steenlant

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut