
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }
use Cradle::Base 'Test';
use Cradle::Job;
use Cradle::Notify::Email;

subtest 'notify' => sub {
    my $job = Cradle::Job->new(
        job_dir => tempdir,
        name => 'JOB_NAME',
    );

    my $result = {
        build_number => 1,
        status => 'success',
    };

    my $mail = Cradle::Notify::Email->new(
        to => 'doug@example.com',
    );
    $mail->notify( success => $job => $result );

    my @deliveries = Email::Sender::Simple->default_transport->deliveries;
    is scalar @deliveries, 1, '1 email sent';
    my $got_delivery = $deliveries[0];
    cmp_deeply $got_delivery->{envelope}, { from => $mail->from, to => [ $mail->to ] },
        'envelope is correct';
    my $got_mail = $got_delivery->{email};
    is $got_mail->get_header( 'Subject' ), 'Cradle job: JOB_NAME (#1): success',
        'subject is correct';
    like $got_mail->get_body, qr{^\QCradle job JOB_NAME (build #1) status is success},
        'body is correct';
};


done_testing;
