use v6;
class Dispatcher;

has @.rules;
has $.default is rw;

#multi method add ($rule) {
method add ($rule) {
    die "Only complite rules accepteable there." unless $rule.?is_complite;
    @!rules.push($rule);
}

#multi method add (@tokens, $way){
#    use Dispatcher::Rule;
#    my $rule =  Dispatcher::Rule.new( tokens => @tokens, way => $way );
#    @!rules.push($rule);
#}



method dispatch (@chunks) {
    # that make clsure:
    #my @applyable =  @!rules.grep: { .is_applyable(@chunks) };    
    # so workaround:

    my @applyable;
    for @!rules -> $r {
        @applyable.push($r) if $r.match(@chunks);
    }
    #say "Applyable:" ~ @applyable;

    if @applyable {
        my $result = @applyable[-1].apply;
        .clear for @!rules; 
        return $result;
    }
    elsif $.default {
        $.default();
    }
    else {
        return False;
    }
}

# vim:ft=perl6