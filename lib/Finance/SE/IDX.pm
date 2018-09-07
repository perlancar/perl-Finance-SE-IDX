package Finance::SE::IDX;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use HTTP::Tiny;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       list_idx_sectors
                       list_idx_boards
                       list_idx_firms
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Get information from Indonesian Stock Exchange',
};

my $urlprefix = "http://www.idx.co.id/umbraco/Surface/";

sub _get_json {
    my $url = shift;

    my $res = HTTP::Tiny->new->get($url);
    return [$res->{status}, $res->{reason}] unless $res->{status} == 200;
    require JSON::MaybeXS;
    [200, "OK", JSON::MaybeXS::decode_json($res->{content})];
}

$SPEC{list_idx_sectors} = {
    v => 1.1,
    summary => 'List sectors',
    args => {
    },
};
sub list_idx_sectors {
    _get_json("${urlprefix}Helper/GetSectors");
}

$SPEC{list_idx_boards} = {
    v => 1.1,
    summary => 'List boards',
    args => {
    },
};
sub list_idx_boards {
    my $res = _get_json("${urlprefix}Helper/GetBoards");
    return $res unless $res->[0] == 200;
    $res->[2] = [grep {$_ ne ''} @{ $res->[2] }];
    $res;
}

$SPEC{list_idx_firms} = {
    v => 1.1,
    summary => 'List firms',
    args => {
        board => {
            schema => ['str*', match=>qr/\A\w+\z/],
            tags => ['category:filtering'],
        },
        sector => {
            schema => ['str*', match=>qr/\A[\w-]+\z/],
            tags => ['category:filtering'],
        },
    },
};
sub list_idx_firms {
    my %args = @_;

    my $sector = $args{sector} // '';
    my $board  = $args{board} // '';

    my @rows;

    # there's a hard limit of 150, let's be nice and ask 100 at a time
    my $start = 0;
    while (1) {
        my $res = _get_json("${urlprefix}StockData/GetSecuritiesStock?code=&sector=$sector&board=$board&draw=3&columns[0][data]=Code&columns[0][name]=&columns[0][searchable]=true&columns[0][orderable]=false&columns[0][search][value]=&columns[0][search][regex]=false&columns[1][data]=Code&columns[1][name]=&columns[1][searchable]=true&columns[1][orderable]=false&columns[1][search][value]=&columns[1][search][regex]=false&columns[2][data]=Name&columns[2][name]=&columns[2][searchable]=true&columns[2][orderable]=false&columns[2][search][value]=&columns[2][search][regex]=false&columns[3][data]=ListingDate&columns[3][name]=&columns[3][searchable]=true&columns[3][orderable]=false&columns[3][search][value]=&columns[3][search][regex]=false&columns[4][data]=Shares&columns[4][name]=&columns[4][searchable]=true&columns[4][orderable]=false&columns[4][search][value]=&columns[4][search][regex]=false&columns[5][data]=ListingBoard&columns[5][name]=&columns[5][searchable]=true&columns[5][orderable]=false&columns[5][search][value]=&columns[5][search][regex]=false&start=$start&length=100&search[value]=&search[regex]=false");
        return $res unless $res->[0] == 200;
        for my $row0 (@{ $res->[2]{data} }) {
            my $listing_date = $row0->{ListingDate}; $listing_date =~ s/T.+//;
            my $row = {
                code  => $row0->{Code},
                name  => $row0->{Name},
                listing_date => $listing_date,
                shares => $row0->{Shares},
                board => $row0->{ListingBoard},
            };
            push @rows, $row;
        }
        if (@{ $res->[2]{data} } == 100) {
            $start += 100;
            next;
        } else {
            last;
        }
    }
    [200, "OK", \@rows, {'table.fields'=>[qw/code name listing_date shares board/]}];
}

1;
# ABSTRACT:
