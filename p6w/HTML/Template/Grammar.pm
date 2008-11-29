grammar HTML::Template::Grammar {
    token TOP { ^ <contents> $ };

    token contents  { <plaintext> <chunk>* };
    token chunk     { <directive> <plaintext> };
    token plaintext { [ <!before '<TMPL_' ><!before '</TMPL_' >. ]* {*} };

    token directive {
                    | <insertion>
                    | <if_statement>
                    | <for_statement>
                    | <include>
                    };

    token insertion {
        <.tag_start> 'VAR' <attributes> '>'
        {*}
    };

    token if_statement { 
        <.tag_start> 'IF' <attributes> '>' 
        <contents>
        [ '<TMPL_ELSE>' <else=contents> ]?
        '</TMPL_IF>'
        {*} 
    };

    token for_statement {
        <.tag_start> 'FOR' <attributes> '>'
        <contents>
        '</TMPL_FOR>'
        {*}
    };

    token include {
        <.tag_start> 'INCLUDE' <attributes> '>'
    };

    token tag_start  { '<TMPL_' };
    token name       { $<val>=\w+ | <.qq> $<val>=[ <[ 0..9 '/._' \- // ] +alpha>* ] <.qq> };
    token qq         { '"' };
    token escape     { 'NONE' | 'HTML' | 'URL' | 'JS' | 'JAVASCRIPT' };
    token attributes { \s+ 'NAME='? <name> [\s+ 'ESCAPE=' <escape> ]? };
};
