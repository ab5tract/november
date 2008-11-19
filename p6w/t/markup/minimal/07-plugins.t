use v6;

use Test;
plan 3;

use Text::Markup::Wiki::Minimal;

my $converter = Text::Markup::Wiki::Minimal.new(
    :link_maker(&make_link),
    :plugin_loader(&plugin_loader),
);

{
    my $input = "<plugin1>frills</plugin1>";
    my $expected_output = '<p>frills</p>';
    my $actual_output = $converter.format( $input );

    is( $actual_output, $expected_output, 'Dummy plugin works' );
}

{
    my $input = "<plugin2>frills</plugin2>\n";
    my $expected_output = "<p>frills\n</p>";
    my $actual_output = $converter.format( $input );

    is( $actual_output, $expected_output, 'Dummy plugin works' );
}

{
    my $input = "some stuff <plugin3>frills</plugin3> some more stuff";
    my $expected_output = '<p>some stuff frills some more stuff</p>';
    my $actual_output = $converter.format( $input );

    is( $actual_output, $expected_output, 'Dummy plugin works' );
}

sub make_link {
    return 'LINK';
}
sub plugin_loader($name, $content) { $content }
