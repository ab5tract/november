use v6;

use CGI;
use Tags;
use HTML::Template;
use Text::Markup::Wiki::Minimal;
use November::Storage::File;  
use Session;
use Dispatcher;
use Utils;

class November does Session {

    has $.template_path;
    has $.userfile_path;

    has November::Storage $.storage;
    has CGI     $.cgi;

    method init {
        # RAKUDO: set the attributes when declaring them
        $!template_path = 'skin/';
        $!userfile_path = 'data/users';

        $!storage = November::Storage::File.new();
        Session::init(self);
    }

    method handle_request(CGI $cgi) {
        $!cgi = $cgi;

        my $action = $cgi.params<action> // 'view';

        my $d = Dispatcher.new( default => { self.not_found } );

        $d.add_rules(
            [
            [''],                { self.view_page },
            ['view', /^ \w+ $/], { self.view_page(~$^page) },
            ['edit', /^ \w+ $/], { self.edit_page(~$^page) },
            ['in'],              { self.log_in },
            ['out'],             { self.log_out },
            ['recent'],          { self.list_recent_changes },
            ['all'],             { self.list_all_pages },
            ]
        );

        my @chunks =  $cgi.uri.chunks.list;
        $d.dispatch(@chunks);
    }

    method view_page($page='Main_Page') {

        unless $.storage.wiki_page_exists($page) {
            self.not_found($page);
            return;
        }

        my $template = HTML::Template.new(
            filename => $.template_path ~ 'view.tmpl');

        $template.param('TITLE' => $page);

        my $minimal = Text::Markup::Wiki::Minimal.new( 
                        link_maker => { self.make_link($^p, $^t) } 
                      );
        $template.param(
            'CONTENT' => $minimal.format($.storage.read_page: $page) 
        );

        # TODO: we need plugin system (see topics in mail-list)
        my $t = Tags.new();
        $template.param( 'PAGETAGS' => $t.page_tags: $page );
        $template.param( 'TAGS'     => $t.cloud_tags );
       
        $template.param('RECENTLY' => self.get_changes: page => $page, 
                                                        limit => 8 );

        $template.param('LOGGED_IN' => self.logged_in);

        $.cgi.send_response(
            $template.output(),
        );
    }

    method edit_page($page) {
        my $sessions = self.read_sessions();

        return self.not_authorized() unless self.logged_in();

        my $already_exists
                        = $.storage.wiki_page_exists($page);
        my $action      = $already_exists ?? 'Editing' !! 'Creating';
        my $old_content = $already_exists ?? $.storage.read_page($page) !! '';
        my $title = "$action $page";

        # The 'edit' action handles both showing the form and accepting the
        # POST data. The difference is the presence of the 'articletext'
        # parameter -- if there is one, the action is considered a save.
        if $.cgi.params<articletext> || $.cgi.params<tags> {
            my $new_text   = $.cgi.params<articletext>;
            my $tags       = $.cgi.params<tags>;
            my $session_id = $.cgi.cookie<session_id>;
            my $author     = $sessions{$session_id}<user_name>;
            $.storage.save_page($page, $new_text, $author);

            # TODO: we need plugin system (see topics in mail-list)
            my $t = Tags.new();
            $t.update_tags($page, $tags);

            $.cgi.redirect('/view/' ~ $page );
            return;
        }

        my $template = HTML::Template.new(
            filename => $.template_path ~ 'edit.tmpl');

        $template.param('PAGE'      => $page);
        $template.param('TITLE'     => $title);
        $template.param('CONTENT'   => $old_content);

        # TODO: we need plugin system (see topics in mail-list)
        my $t = Tags.new;
        $template.param('PAGETAGS' => $t.read_page_tags: $page);

        $template.param('LOGGED_IN' => True);

        $.cgi.send_response(
            $template.output(),
        );
    }

    method logged_in() {
        my $sessions = self.read_sessions();
        my $session_id = $.cgi.cookie<session_id>;
        # RAKUDO: 'defined' should maybe be 'exists', although here it doesn't
        # matter.
        defined $session_id && defined $sessions{$session_id}
    }

    method not_authorized {
        my $template = HTML::Template.new(
            filename => $.template_path ~ 'action_not_authorized.tmpl');

        # TODO: file bug, without "'" it is interpreted as named args and not
        #       as Pair
        $template.param('DISALLOWED_ACTION' => 'edit pages');

        $.cgi.send_response(
            $template.output(),
        );

        return;
    }

    method read_users {
        return {} unless $.userfile_path ~~ :e;
        return eval( slurp( $.userfile_path ) );
    }

    method not_found($page?) {
        my $template = HTML::Template.new(
            filename => $.template_path ~ 'not_found.tmpl');

        $template.param('PAGE'      => $page || 'Action Not found');
        $template.param('LOGGED_IN' => self.logged_in());

        $.cgi.send_response(
            $template.output(),
        );
        return;
    }

    method log_in {
        if my $user_name = $.cgi.params<user_name> {

            my $password = $.cgi.params<password>;

            my %users = self.read_users();

            # Yes, this is cheating. Stand by for a real MD5 hasher.
            if (defined %users{$user_name} 
               and $password eq %users{$user_name}<plain_text>) {
#            if Digest::MD5::md5_base64(
#                   Digest::MD5::md5_base64($user_name) ~ $password
#               ) eq %users{$user_name}<password> {

                my $session_id = self.new_session($user_name);
                my $session_cookie = "session_id=$session_id";

                my $template = HTML::Template.new(
                    filename => $.template_path ~ 'login_succeeded.tmpl');

                $.cgi.send_response(
                    $template.output(),
                    { cookie => $session_cookie }
                );

                return;
            }

            my $template = HTML::Template.new(
                filename => $.template_path ~ 'login_failed.tmpl');

            $.cgi.send_response(
                $template.output(),
            );

            return;
        }

        my $template = HTML::Template.new(
            filename => $.template_path ~ 'log_in.tmpl');

        $.cgi.send_response(
            $template.output(),
        );

        return;
    }

    method log_out {
        if defined $.cgi.cookie<session_id> {

            my $session_id = $.cgi.cookie<session_id>;
            self.remove_session( $session_id );

            my $session_cookie = "session_id=";

            my $template = HTML::Template.new(
                filename => $.template_path ~ 'logout_succeeded.tmpl');

            $.cgi.send_response(
                $template.output(),
                { :cookie($session_cookie) }
            );

            return;
        }

        my $template = HTML::Template.new(
            filename => $.template_path ~ 'logout_succeeded.tmpl');

        $.cgi.send_response(
            $template.output(),
        );

        return;
    }

    method make_link($page, $title?) {
        if $title {
            if $page ~~ m/':'/ {
                return "<a href=\"$page\">$title</a>";
            } else {
                return "<a href=\"/view/$page\">$title</a>";
            }
        } else {
            return sprintf('<a href="/%s/%s" %s >%s</a>',
                           $.storage.wiki_page_exists($page)
                             ?? ('view', $page, '')
                             !! ('edit', $page, ' class="nonexistent"'),
                           $page);
        }
    }

    method list_recent_changes {
        my @changes = self.get_changes(limit => 50);
        my $template = HTML::Template.new(
                filename => $.template_path ~ 'recent_changes.tmpl');

        $template.param('CHANGES'   => @changes);
        $template.param('LOGGED_IN' => self.logged_in());

        $.cgi.send_response(
            $template.output()
        );

        return;
    }

    method get_changes (:$page, :$limit) {

        # RAKUDO: Seemingly impossible to get the right number of list
        # containers using an array variable @recent_changes here.
        my $recent_changes;

        if $page {
            $recent_changes = $.storage.read_page_history($page);
        }
        else {
            $recent_changes = $.storage.read_recent_changes;
        }

        # @recent_changes = @recent_changes[0..$limit] if $limit;
        # RAKUDO: array slices do not implemented yet, so:
        my @changes;
        for $recent_changes.list -> $modification_id {
            my $modification = $.storage.read_modification($modification_id);
            my $count = push @changes, {
                'page' => self.make_link($modification[0]),
                'time' => time_to_period_str($modification[3]) || $modification_id,
                'author' => $modification[2] || 'somebody' 
                };
            # RAKUDO: last not implemented yet :(
            return @changes if $limit && $count == $limit;
        }
        return @changes;
    }

    method list_all_pages {
        my $template = HTML::Template.new(
                filename => $.template_path ~ 'list_all_pages.tmpl');

        my $t = Tags.new();
        $template.param('TAGS' => $t.cloud_tags) if $t;

        my $index;

        my $tag = $.cgi.params<tag>;
        if $tag and $t {
            # TODO: we need plugin system (see topics in mail-list)
            my $tags_index = $t.read_tags_index;
            $index = $tags_index{$tag};
    
            $template.param('TAG' => $tag );
        } 
        else {
            $index = $.storage.read_index;
        }

        if $index {
            # HTML::Template eat only Arrey of Hashes and Hash keys should 
            # be in low case. HTML::Template in new-html-template brunch 
            # will be much clever.

            # RAKUDO: @($arrayref) not implemented yet, so:
            # my @list = map { { page => $_ } }, @($index); 
            # do not work. Workaround:
            my @list = map { { page => $_ } }, $index.list; 
            $template.param('LIST' => @list);
        }

        $template.param('LOGGED_IN' => self.logged_in);

        $.cgi.send_response(
            $template.output()
        );
    }
}

# vim:ft=perl6
