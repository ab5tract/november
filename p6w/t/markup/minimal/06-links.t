use v6;

use Test;
plan 3;

use Text::Markup::Wiki::Minimal;

my $converter = Text::Markup::Wiki::Minimal.new;

{
    my $input = 'An example of a [[link]]';
    my $expected_output
        = '<p>An example of a <a href="/?page=link">link</a></p>';
    my $actual_output = $converter.format($input);

    is( $expected_output, $actual_output, 'link conversion works' );
}

{
    my $input = 'An example of a [[malformed link';
    my $expected_output = '<p>An example of a [[malformed link</p>';
    my $actual_output = $converter.format($input);

    is( $expected_output, $actual_output, 'malformed link I' );
}

{
    my $input = 'An example of a malformed link]]';
    my $expected_output = '<p>An example of a malformed link]]</p>';
    my $actual_output = $converter.format($input);

    is( $expected_output, $actual_output, 'malformed link II' );
}