package TransmissionIdentifierBase;

# routines used for both training and classification

use Mouse;

use Audio::Wav;

#has 'input'    => (is => 'rw', isa => 'Str', required => 1);
#has 'output'   => (is => 'rw', isa => 'Str', required => 1);
#has 'duration' => (is => 'rw', isa => 'Int', required => 1);

use Types::Standard qw( Int Str Num);
use Params::ValidationCompiler qw( validation_for );

my $validator = validation_for(
    params => {
	input    => { type => Str },
	output   => { type => Str },
	duration => { type => Num, optional => 1 },
    },
);

sub audio_to_spectrogram {
    my $self = shift;
    my %args = $validator->(@_);

    die "audio file $args{input} not found" if !-e $args{input};

    if (!exists($args{duration})) {
	my $wav = Audio::Wav->new;
	my $read = $wav->read( $args{input} );
	$args{duration} = $read->length_seconds;
	$read->{handle}->close;    # http://www.perlmonks.org/bare/?node_id=946696
    }


    # /usr/bin/ffmpeg -loglevel error -y -i audio.wav -ss 00:00:00 -t 00:00:01 -lavfi showspectrumpic=s=100x50:scale=log:legend=off audio.png
    my $start = $args{duration}/2-0.5;
    my @args = ( '/usr/bin/ffmpeg',  '-loglevel', 'error', '-y', '-ss', $start, '-t', 1.0, '-i', $args{input},
                  '-lavfi',  'showspectrumpic=s=100x50:scale=log:legend=off',  $args{output});
    if (system( @args ) != 0) {
	my $err = "system @args failed: $?";
	#$self->{app}->log->error($err);
	die $err;
    }
    return;
}

1;
