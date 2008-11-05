use v6;
use November__Storage;
use Impatience;

class November::Storage::File is November__Storage {
    my $.content_path        = 'data/articles/';
    my $.modifications_path  = 'data/modifications/';
    my $.recent_changes_path = 'data/recent-changes';
    my $.index_path          = 'data/index';

    method wiki_page_exists($page) {
        return ($.content_path ~ $page) ~~ :e;
    }

    method read_recent_changes {
        return [] unless $.recent_changes_path ~~ :e;
        return eval( slurp( $.recent_changes_path ) );
    }

    method write_recent_changes ( $recent_changes ) {
        my $fh = open($.recent_changes_path, :w);
        $fh.say($recent_changes.perl);
        $fh.close;
    }

    method read_page_history($page) {
        my $file = $.content_path ~ $page;
        return [] unless $file ~~ :e;
        my $page_history = eval( slurp($file) );
        return $page_history;
    }

    method write_page_history( $page, $page_history ) {
        my $file = $.content_path ~ $page;
        my $fh = open($file, :w);
        $fh.say( $page_history.perl );
        $fh.close;
    }

    method read_modification($modification_id) {
        my $file = $.modifications_path ~ $modification_id;
        return [] unless $file ~~ :e;
        return eval( slurp($file) );
    }

    method write_modification ( $modification_id, $modification ) {
        my $data = $modification.perl;
        r_remove($data);

        my $file =  $.modifications_path ~ $modification_id;
        my $fh = open( $file, :w );
        $fh.say( $data );
        $fh.close();
    }

    method add_to_index ($page) {
        my $index = self.read_index;
        $index.push($page);
        my $fh = open($.index_path, :w);
        $fh.say($index.perl);
        $fh.close;
    }

    method read_index {
        return eval( slurp($.index_path) );
    }
}

# vim:ft=perl6