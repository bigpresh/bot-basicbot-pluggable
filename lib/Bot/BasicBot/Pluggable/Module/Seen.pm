package Bot::BasicBot::Pluggable::Module::Seen;
use Bot::BasicBot::Pluggable::Module::Base;
use base qw(Bot::BasicBot::Pluggable::Module::Base);

=head1 NAME

Bot::BasicBot::Pluggable::Module::Seen

=head1 SYNOPSIS

Keeps track of when people were last seen, and where.

=head1 IRC USAGE

Commands:

=over 4

=item seen <nick>

When did I last see <nick>

=item hide

Hide from the seen reporting

=item unhide

Stops hiding

=back

=cut


sub help {
    return "Tracks seen status of people. say 'seen <nick>' to find out where I last saw someone. Tell me 'hide' and I'll stop tracking you, stop with 'unhide'.";
}


sub said {
    my ($self, $mess, $pri) = @_;
    my $body = $mess->{body};

    if ($pri == 0) {
        $self->{store}{seen}{lc($mess->{who})}{time} = time;
        $self->{store}{seen}{lc($mess->{who})}{channel} = $mess->{channel};
        $self->{store}{seen}{lc($mess->{who})}{what} =
            $mess->{channel} ne 'msg' ? $mess->{body} : '<private message>';
        $self->save();
        return undef;
    }

    return undef unless ($pri == 2);

    my ($command, $param) = split(/\s+/, $body, 2);
    $command = lc($command);

    if ($command eq "seen" and $param =~ /^(\w+)\??$/) {
        my $who = $1;
        my $seen = $self->{store}{seen}{lc($who)};
        if ($self->{store}{hidden}{lc($who)} or !$seen) {
            return "Sorry, I haven't seen $who";
        }
        my $diff = time - $seen->{time};
        my $time_string = secs_to_string($diff);
        $mess->{address} = undef;
        return "$who was last seen in $seen->{channel} $time_string saying '$seen->{what}'";

    } elsif ($command eq "hide" and $mess->{address}) {
        $self->{store}{hidden}{lc($mess->{who})}++;
        $self->save();
        return "Ok, you're hiding";
    } elsif ($command eq "unhide" and $mess->{address}) {
        delete $self->{store}{hidden}{lc($mess->{who})};
        $self->save();
        return "Ok, you're visible";
    }


    return undef;
}

sub secs_to_string {
    my $secs = shift;

    # Hopefully never used. But if the seen time is in the future,
    # catch it.
    my $weird = 0;
    if ($secs < 0) {
        $secs = -$secs;
        $weird = 1;
    }

    my $days = int($secs / 86400);
    $secs = $secs % 86400;
    my $hours = int($secs / 3600);
    $secs = $secs % 3600;
    my $mins = int($secs / 60);
    $secs = $secs % 60;
    
    my $string;
    $string .= "$days days " if $days;
    $string .= "$hours hours " if $hours;
    $string .= "$mins mins " if ($mins and !$days);
    $string .= "$secs seconds " if (!$days and !$hours);

    return $string. ($weird ? "in the FUTURE!!!" : "ago");
}


1;