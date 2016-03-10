package Cradle::Notify::Email;

# ABSTRACT: Notify about jobs via e-mail

=head1 SYNOPSIS

    # job/config.yml
    mailer:
        $class: Cradle::Notify::Email
        to: preaction@example.com
        smtp_host: mail.example.com
        smtp_user: mail_user
        smtp_pass: mail_pass

    notify:
        fail:
            ref: $mailer
        success:
            ref: $mailer

=head1 DESCRIPTION

Send out notifications of build results via e-mail.

=cut

use Cradle::Base 'Class';
use Email::Sender::Simple qw( sendmail );
use Email::Simple;
use Sys::Hostname qw( hostname );

=attr to

The address to send mail to. Required.

=cut

has to => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr from

The address to send mail from. Defaults to C<< cradle@<hostname> >>.

=cut

has from => (
    is => 'ro',
    isa => Str,
    default => sub { 'cradle@' . hostname },
);

=attr smtp_host

The SMTP host to send mail through. Defaults to C<localhost>.

=cut

has smtp_host => (
    is => 'ro',
    isa => Str,
    default => sub { 'localhost' },
);

=attr smtp_port

The SMTP port to send mail through. Defaults to C<25>.

=cut

has smtp_port => (
    is => 'ro',
    isa => Int,
    default => sub { 25 },
);

=attr smtp_user

The user to authenticate to the SMTP server. If set, will perform SMTP
authentication. Defaults to unset. Use with L<the smtp_pass
attribute|/smtp_pass>.

=cut

has smtp_user => (
    is => 'ro',
    isa => Maybe[Str],
);

=attr smtp_pass

The password to authenticate to the SMTP server. If combined with L<the
smtp_user attribute|/smtp_user>, will perform SMTP authentication.
Defaults to unset.

=cut

has smtp_pass => (
    is => 'ro',
    isa => Maybe[Str],
);

=method notify

    $mail->notify( $event, $job, $result );

Send out the given notification for the given job.

=cut

sub notify {
    my ( $self, $event, $job, $result ) = @_;

    my $subject = sprintf 'Cradle job: %s (#%i): %s', $job->name, $result->{build_number}, $event;

    my $msg = Email::Simple->create(
        header => [
            From => $self->from,
            To => $self->to,
            Subject => $subject,
        ],
        body => sprintf(
            'Cradle job %s (build #%i) status is %s',
            $job->name,
            $result->{build_number},
            $event,
        ),
    );

    sendmail( $msg );
}

1;

