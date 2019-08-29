use ExtUtils::MakeMaker;

my $preop =
    'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod';

WriteMakefile(
    NAME            => 'TransmissionIdentifier',
    VERSION_FROM    => 'lib/TransmissionIdentifier.pm',
    PREREQ_PM => {
        'AI::MXNet'                         => 0,
        'AI::MXNet::Gluon'                  => 0,
        'AI::MXNet::AutoGrad'               => 0,
        'AI::MXNet::Gluon::NN'              => 0,
        'AI::MXNet::Base'                   => 0,
        'strict'                            => 0,
        'warnings'                          => 0,
    },
    dist                => {
	PREOP => $preop,
    },
    LICENSE  => 'perl_5',
    META_MERGE => {
        resources => {
	    license     => [ 'http://dev.perl.org/licenses/' ],
	    repository  => {
	        web  => 'git@github.com:john-/xmit_mxnet.git',
	    },
        },
    },
);
