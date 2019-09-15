package TransmissionIdentifier;

use Mouse;

#use Types::Standard qw( Int Str Bool);
#use Params::ValidationCompiler qw( validation_for );

extends 'TransmissionIdentifierBase';

#use Method::Signatures;

has 'hybridize'   => (is => 'ro', isa => 'Bool', default => 0);
has 'load_params' => (is => 'ro', isa => 'Bool', default => 0);
has 'params'      => (is => 'ro', isa => 'Str',  default => 'xmit.params');
has 'labels'      => (is => 'ro', isa => 'Str',  default => 'labels.txt');
has 'net'         => (is => 'ro',
                      isa => 'AI::MXNet::Gluon::NN::Sequential',
		      builder => '_net',
                      );
has 'batch_size'  =>  (is => 'rw', isa => 'Int', default => 1);

# code borrows extensively from at least the following:

# https://github.com/apache/incubator-mxnet/blob/master/perl-package/AI-MXNet/examples/gluon/mnist.pl
# http://blogs.perl.org/users/sergey_kolychev/2017/10/machine-learning-in-perl-part3-deep-convolutional-generative-adversarial-network.html
# https://www.doviak.net/pages/mxnet/mxnet_p05.shtml

use AI::MXNet qw(mx);
use AI::MXNet::Gluon qw(gluon);
use AI::MXNet::AutoGrad qw(autograd);
use AI::MXNet::Gluon::NN qw(nn);
use AI::MXNet::Base;
use Getopt::Long qw(HelpMessage);
use Data::Dumper;

use feature 'say';

our $VERSION = '1.0';

sub _net {
    my $self = shift;

    my $net = nn->Sequential();
    $net->name_scope(
        sub {
            $net->add(
                nn->Conv2D(
                    channels    => 6,
                    kernel_size => 5,
                    activation  => 'relu'
                )
            );
            $net->add( nn->MaxPool2D( pool_size => 2, strides => 2 ) );
            $net->add(
                nn->Conv2D(
                    channels    => 16,
                    kernel_size => 3,
                    activation  => 'relu'
                )
            );
            $net->add( nn->MaxPool2D( pool_size => 2, strides => 2 ) );
            $net->add( nn->Flatten() );
            $net->add( nn->Dense( 120, activation => "relu" ) );
            $net->add( nn->Dense( 84,  activation => "relu" ) );
            $net->add( nn->Dense(2) );
        }
    );

    $net->hybridize() if $self->hybridize;

    #$self->{net} = $net;

    if ($self->load_params) {
	#my $self->{params} = $self->params_dir . 'xmit.params';
        if (-e $self->params) {
	    $net->load_parameters($self->params);
        } else {
	    die sprintf('param file not found: %s', $self->params);
	}
    }

    if (-e $self->labels) {
	open my $fh, '<', $self->labels;
	chomp(@{$self->{text_labels}} = <$fh>);
	close $fh;
    } else {
	die sprintf('labels file not found: %s', $self->labels);
    }

    $self->{ctx} = $self->{cuda} ? mx->gpu(0) : mx->cpu;

    return $net;
}

sub transformer {
    my ( $data, $label ) = @_;

    # put channel first
    $data = $data->transpose( [ 2, 0, 1 ] );  # change to channel, height, width
    $data = $data->astype('float32') / 255.0;

    return ( $data, $label );
}

sub _data_setup {
    my $self = shift;

    return if exists $self->{train_data};

    $self->{train_dataset} = gluon->data->vision->ImageFolderDataset(
        root      => './training/train',
        flag      => 1,
        transform => \&transformer
    );

    $self->{train_data} = gluon->data->DataLoader(
        $self->{train_dataset},
        batch_size => $self->batch_size,
        shuffle    => 1,
        last_batch => 'discard'
    );

    $self->{val_dataset} = gluon->data->vision->ImageFolderDataset(
        root      => './training/test',
        flag      => 1,
        transform => \&transformer
    );
    $self->{val_data} = gluon->data->DataLoader(
        $self->{val_dataset},
        batch_size => $self->batch_size,
        shuffle    => 0
    );

    # write out labels
    open(my $fh, '>', $self->{label_file}) or die $!;
    foreach (@{ $self->{train_dataset}->synsets }) {
        print $fh "$_\n";
    }
    close($fh);
}

sub _collect_args {
    my ( $self, $args ) = @_;

#    $self->{batch_size} =
#      exists( $args->{batch_size} ) ? $args->{batch_size} : 1;
    $self->{cuda}     = exists( $args->{cuda} )     ? $args->{cuda}     : 0;
    $self->{epochs}   = exists( $args->{epochs} )   ? $args->{epochs}   : 20;
    $self->{lr}       = exists( $args->{lr} )       ? $args->{lr}       : 0.001;
    $self->{momentum} = exists( $args->{momentum} ) ? $args->{momentum} : 0.9;
    $self->{log_intrvl} =
      exists( $args->{log_intrvl} ) ? $args->{log_intrvl} : 100;
}

sub write_image {
    my ( $self, $data, $location ) = @_;

    $data = $data->at(0)->aspdl;

    if ( $data->getdim(2) == 3 ) {    # color:
        $data = $data->reorder( 2, 0, 1 )->slice( 'x', 'x', '-1:0' );
                                      # RGB first then invert
    }
    else {                            # grayscale:
        $data = $data->squeeze->slice( 'x', '-1:0' ); # remove uneeded dimension
                                                      # then invert image
    }

    my $image = ( $data * 255 )->byte;

    $image->wpic($location);
}

sub dump_all_images {
    my ( $self, $set_ref ) = @_;

    my @set = @$set_ref;
    mkdir "image_dump";
    for my $i ( 0 .. $#set ) {
        my $data = ${ $set[$i] }[0];

        #my $label = ${ $set[$i] }[1];

        $self->write_image( $data, "image_dump/$i.png" );
    }
}

sub get_mislabeled {
    my ( $self, $loader ) = @_;

    mkdir "mislabeled";

    my @tendl = @$loader;

    my $topline;
    $topline .= '  PREDICTION :: CORRECT' . "\n";
    $topline .= '  ========== :: =======' . "\n";

    print $topline;

    for my $i ( 0 .. $#tendl ) {
        my $data  = ${ $tendl[$i] }[0];
        my $label = ${ $tendl[$i] }[1];

        my $ot   = $self->net->($data)->argmax( { axis => 1 } );
        my $pred = $self->{text_labels}[ PDL::sclr( $ot->aspdl ) ];
        my $true = $self->{text_labels}[ PDL::sclr( $label->aspdl ) ];

        my $otline;
        $otline .= sprintf( "%12s",  $pred ) . " :: ";
        $otline .= sprintf( "%-10s", $true ) . " ";

        #$otline .= ( $pred eq $true ) ? ".." : "XX";
        if ( $pred eq $true ) {
            $otline .= "..";
        }
        else {
            $otline .= "XX";
            my $hashish = int( $data->aspdl->sum );
            $self->write_image( $data,
                sprintf( "mislabeled/%s-%s.png", $hashish, $true ) );
        }

        print $otline . "\n";

    }
}

sub is_voice {
    my ( $self, $file ) = @_;

    die 'need to load params if going to classify' if !$self->load_params;

    if ($file =~ m/\.wav$/) {
        my $wav = $file;
        $file = '/tmp/classify.png';
	$self->audio_to_spectrogram( input  => $wav,
				     output => $file );
    }

    my $image = mx->image->imread($file);

    # put channel first
    $image = $image->transpose( [ 2, 0, 1 ] )->expand_dims( axis => 0 );
           # change to batch, channel,
           # height, width
    $image = $image->astype('float32') / 255.0;

    my $prob = $self->net->($image)->softmax;

    my $idxs = $prob->topk( k => 0 )->at(0);
    my $top_idx = $idxs->[0]->asscalar;
    my $top_prob = $prob->at(0)->at($top_idx)->asscalar;
    my $top_label = $self->{text_labels}->[$top_idx];

    #my %classifications;
    #for my $idx ( @{ $prob->topk( k => 0 )->at(0) } ) {
    #    my $i = $idx->asscalar;
	#$classifications{ $self->{text_labels}->[$i] } =
	 #   $prob->at(0)->at($i)->asscalar;

     #   printf(
     #       "With prob = %.5f, it contains %s\n",
     #       $prob->at(0)->at($i)->asscalar,
     #       $self->{text_labels}->[$i]
     #   );
    #}
    #return \%classifications;
    if (($top_label eq 'voice') and
	($top_prob  >= 0.5)) {
	    return 1;
    } else {
	return 0;
    }
}

sub test {
    my $self = shift;

    my $ctx = $self->{ctx};

    my $metric  = mx->metric->Accuracy();
    my $val_set = $self->{val_data};
    while ( defined( my $d = <$val_set> ) ) {
        my ( $data, $label ) = @$d;
        $data  = $data->as_in_context($ctx);
        $label = $label->as_in_context($ctx);
        my $output = $self->net->($data);
        $metric->update( [$label], [$output] );
    }
    return $metric->get;
}

sub train {
    my ( $self, $args ) = @_;

    $self->_collect_args($args);

    my $ctx = $self->{ctx};

    $self->_data_setup;

    # Collect all parameters from net and its children, then initialize them.
    $self->net
      ->initialize( mx->init->Xavier( magnitude => 2.24 ), ctx => $ctx );

    # Trainer is for updating parameters with gradient.
    my $trainer = gluon->Trainer( $self->net->collect_params(),
        'sgd',
        { learning_rate => $self->{lr}, momentum => $self->{momentum} } );
    my $metric = mx->metric->Accuracy();
    my $loss   = gluon->loss->SoftmaxCrossEntropyLoss();

    for my $epoch ( 0 .. $self->{epochs} - 1 ) {

        ## set scalars to hold time and mean loss
        my $time = time();
        my $lm;

        # reset data iterator and metric at begining of epoch.
        $metric->reset();
        my $data;
        my $label;
        enumerate(
            sub {
                my ( $i, $d ) = @_;
                ( $data, $label ) = @$d;
                $data  = $data->as_in_context($ctx);
                $label = $label->as_in_context($ctx);

                # Start recording computation graph with record() section.
                # Recorded graphs can then be differentiated with backward.
                my $output;
                my $L;
                autograd->record(
                    sub {
                        $output = $self->net->($data);
                        $L      = $loss->( $output, $label );
                        $L->backward;
                    }
                );

                ## capture the mean loss
                $lm = PDL::sclr( $L->mean->aspdl );

                # take a gradient step with batch_size equal to data.shape[0]
                $trainer->step( $data->shape->[0] );

                # update metric at last.
                $metric->update( [$label], [$output] );

                if (    $self->{log_intrvl} > 0
                    and $i % $self->{log_intrvl} == 0
                    and $i > 0 )
                {
                    my ( $name, $acc ) = $metric->get();
                    print "[Epoch $epoch Batch $i] Training: $name=$acc\n";
                }
            },
            \@{ $self->{train_data} }
        );

        my ( $trn_name, $trn_acc ) = $metric->get();

        #visualize( $data, $epoch );

        my ( $val_name, $val_acc ) = $self->test;

        ## capture time interval
        my $nowtime  = time();
        my $interval = $nowtime - $time;

        say sprintf(
            'Epoch %d: loss %.3f, train acc %.3f, test acc %.3f in %0.1f secs',
            $epoch, $lm, $trn_acc, $val_acc, $interval );

    }
    $self->get_mislabeled( $self->{val_data} );
    $self->net->save_parameters($self->{params});

}

sub info {
    my ( $self, $args ) = @_;

    $self->_data_setup;

    my $sample = $self->{train_data}->[0];
    my $data   = $sample->[0];
    my $label  = $sample->[1];
    say sprintf( 'data type: %s label type: %s', $data->dtype, $label->dtype );
    say Dumper( $data->at(0)->shape );

    say sprintf(
        'sample image name: %s, label: %s',
        $self->{train_dataset}->items->[0][0],
        $self->{train_dataset}->items->[0][1]
    );
    say sprintf( 'batch size: %s', $data->len );
    say 'labels:';
    foreach my $label ( @{ $self->{train_dataset}->synsets } ) {
        say sprintf( ' label: %s', $label );
    }
    say sprintf( 'total training data: %d',   $self->{train_dataset}->len );
    say sprintf( 'total validation data: %d', $self->{val_dataset}->len );

    # dump_all_images was mostly done as leaning experience
    #$self->dump_all_images( $self->{train_data} );
}

1;
