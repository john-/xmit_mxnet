package TransmissionIdentifierBase;

# routines used for both training and classification

use Mouse;
use MouseX::Params::Validate;

use Audio::Wav;

# shorten audio files for training
sub audio_for_training {
    my ($self, %params) = validated_hash(
	\@_,
	input =>    {isa => 'Str'},
	output =>   {isa => 'Str'},
	duration => {isa => 'Num', optional => 1},
    );

    die sprintf('audio file %s not found', $params{input}) if !-e $params{input};

    if (!defined($params{duration})) {
	my $wav = Audio::Wav->new;
	my $read = $wav->read( $params{input} );
	$params{duration} = $read->length_seconds;
	$read->{handle}->close;    # http://www.perlmonks.org/bare/?node_id=946696
    }

    my $start = sprintf('%.3f', $params{duration}/2-1.0);  # will get 2 seconds from the middle

    my @args = ( '/usr/bin/ffmpeg',  '-loglevel', 'error', '-y', '-ss', $start, '-t', 2.0,
                  '-i', $params{input},
                  $params{output});
    if (system( @args ) != 0) {
	my $err = "system @args failed: $?";
	die $err;
    }

    return $params{output};
}

sub audio_to_spectrogram {
    my ($self, %params) = validated_hash(
	\@_,
	input =>    {isa => 'Str'},
	output =>   {isa => 'Str'},
	duration => {isa => 'Num', optional => 1},
    );

    die sprintf('audio file %s not found', $params{input}) if !-e $params{input};

    if (!defined($params{duration})) {
	my $wav = Audio::Wav->new;
	my $read = $wav->read( $params{input} );
	$params{duration} = $read->length_seconds;
	$read->{handle}->close;    # http://www.perlmonks.org/bare/?node_id=946696
    }

    my $start = sprintf('%.3f', $params{duration}/2-0.5);

    my @args = ( '/usr/bin/ffmpeg',  '-loglevel', 'error', '-y', '-ss', $start, '-t', 1.0,
                  '-i', $params{input},
                  '-lavfi',  'showspectrumpic=s=100x50:scale=log:legend=off',  $params{output});
    if (system( @args ) != 0) {
	my $err = "system @args failed: $?";
	die $err;
    }
    return $params{output};
}

1;
