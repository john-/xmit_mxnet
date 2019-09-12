package TransmissionIdentifierBase;

# routines used for both training and classification

use Mouse;

use Method::Signatures;

use Audio::Wav;

#use Types::Standard qw( Int Str Num);
#use Params::ValidationCompiler qw( validation_for );

#my $validator = validation_for(
#    params => {
#	input    => { type => Str },
#	output   => { type => Str },
#	duration => { type => Num, optional => 1 },
#    },
#);

method audio_to_spectrogram(Str :$input!, Str :$output!, Num :$duration)  {
#    my $self = shift;
#    my %args = $validator->(@_);

    die sprintf('audio file %s not found', $input) if !-e $input;

    if (!defined($duration)) {
	my $wav = Audio::Wav->new;
	my $read = $wav->read( $input );
	$duration = $read->length_seconds;
	$read->{handle}->close;    # http://www.perlmonks.org/bare/?node_id=946696
    }

    my $start = $duration/2-0.5;
    my @args = ( '/usr/bin/ffmpeg',  '-loglevel', 'error', '-y', '-ss', $start, '-t', 1.0,
                  '-i', $input,
                  '-lavfi',  'showspectrumpic=s=100x50:scale=log:legend=off',  $output);
    if (system( @args ) != 0) {
	my $err = "system @args failed: $?";
	die $err;
    }
    return;
}

1;
