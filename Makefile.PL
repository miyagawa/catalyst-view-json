use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Catalyst::View::JSON',
    'VERSION_FROM' => 'lib/Catalyst/View/JSON.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        JSON::Any => 1.00,
        Catalyst => 5.60,
    },
);
