use BiBTeXML::Common::Test;
use Test::More tests => 3;

subtest "requirements" => sub {
  plan tests => 1;

  use_ok("BiBTeXML::Runtime::Utils");
};

subtest "concatString" => sub {
  plan tests => 4;

  sub isConcatString {
    my ($a, $b, $c, $d, $expected, $name) = @_;
    is_deeply([concatString($a, $b, $c, $d)], $expected, $name);
  }

  isConcatString(
    ['hello '], [['key1', 'item1']],
    ['world'], [['key2', 'item2']], 

    [['hello ', 'world'], [ ['key1', 'item1'], ['key2', 'item2'] ]],

    'joining two simple strings'
  );

  isConcatString(
    ['hello'], [undef], 
    ['', ''], [undef, ['key', 'item']], 

    [['hello'], [undef]],

    'empty strings are omitted'
  );

  isConcatString(
    ['hello '], [undef], 
    ['world'], [undef], 

    [['hello world'], [undef]],

    'two strings of undefined sources are joined'
  );

  isConcatString(
    ['hello ', '', 'world'], 
    [undef, undef, ['key', 'item']], 
    [' ', '', 'are you listening?'], 
    [undef, ['key2', 'item2'], undef], 
      
    [['hello ', 'world', ' are you listening?'], [undef, ['key', 'item'], undef]], 
    
    'complicated example'
  );
};

subtest "simplifyString" => sub {
  plan tests => 4;

  sub isSimplifyString {
    my ($a, $b, $expected, $name) = @_;
    
    is_deeply([simplifyString($a, $b)], $expected, $name);
  }

  isSimplifyString(
      ['hello world'],
      [['key1', 'item1']], 

      ['hello world', ['key1', 'item1']],
      'simplify string with one defined source'
  );

  isSimplifyString(
      ['hello world'],
      [undef], 

      ['hello world', undef],
      'simplify string with one undefined source'
  );

  isSimplifyString(
      ['hello ', 'world'],
      [['key1', 'item1'], ['key2', 'item2']], 

      ['hello world', ['key1', 'item1']],
      'string with two defined sources'
  );

  isSimplifyString(
      ['hello ', 'world'],
      [undef, ['key2', 'item2']], 

      ['hello world', ['key2', 'item2']],
      'string with one defined and one undefined source'
  );

};
