use v6;

# RAKDUO: :: in class names doesn't fully work
class November__Storage {
    method wiki_page_exists($page)                               { ... }

    method read_recent_changes()                                 { ... }
    method write_recent_changes( $recent_changes )               { ... }

    method read_page_history($page)                              { ... }
    method write_page_history( $page, $page_history )            { ... }

    method read_modification($modification_id)                   { ... }
    method write_modification( $modification_id, $modification ) { ... }


    method save_page($page, $new_text, $author, $tags) {
        my $modification_id = get_unique_id();

        my $page_history = self.read_page_history($page);
        $page_history.unshift( $modification_id );
        self.write_page_history( $page, $page_history );

        self.write_modification( $modification_id, 
                                 [ $page, $new_text, $author] );
    }

    method add_recent_change( $modification_id ) {
        my $recent_changes = self.read_recent_changes();
        $recent_changes.unshift($modification_id);
        self.write_recent_changes( $recent_changes );
    }

    method read_page($page) {
        my $page_history = self.read_page_history($page);
        return "" unless $page_history;
        my $latest_change = self.read_modification( $page_history.shift );
        return $latest_change[1];
    }
}