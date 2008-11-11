use v6;
class HTML::Template::Act;

has %.params is rw;
has $.out;

method plaintext ($m) {
    $!out ~= $m;
}

method insertion ($m) {
    use Text::Escape;
    my $name = ~$m<attributes><name>;
    my $esc_type = %($m<attributes>)<escape>;
    my $value = %.params{$name};
    $value = escape($value, $esc_type ) if $esc_type;
    $!out ~= $value;
}

method if_statement ($m) {
    my $name = ~$m<attributes><name>;
    unless %.params{$name} {
        # hmm.
    }
}

# vim:ft=perl6
