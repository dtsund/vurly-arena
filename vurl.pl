1;
=pod
vurl! :)
by Tim Goodwyn

Thanks to the people of #internets and #cheesebin on QuakeNet for suggestions/halp!


##########################
HOW IT WORKS
love from al
#########################

Note the use of =pod and =cut! These are native to perl 5ish.

Right so there's this hash array called %command. This is a list of
key=>value pairs (cos hash lol). Each key is the foo in !foo and each value
is a reference to another hash. This hash has a reference to a sub and a
usage string. This will make more sense if you look at it.

OK so far?

Good.

The value passed into the sub is always and forever going to be the string
after the command, not including the space between the command and the
arguments. This is currently the entire function of the parse_command sub.
This is called by the parse_all sub, which itself is called by the message
handler. The message handler does not alter the message at all before passing
it to parse_all.

First, it parses variables out of the $text. It does this by finding a match
for &(foo). It then sends foo back into the variable parser, so if foo itself
contains a variable, that will be parsed too. If it doesn't, however, it won't
change, and so the recursion won't continue, and will begin to unfold.

parse_variables returns the string you passed in, except with the variables
replaced with the relevant value from the %variable hash. %variable is used 
for all variables, including &(ans). It also stores all user variables created
with !store.

parse_all then parses out commands (calculations) of the format %(foo). The 
same goes for parse_calculations as goes for parse_variables: the matched 
string foo is itself parsed and recursion unfolds when foo contains no further
commands.

The clever bit is this. Because, as you'll see, parse_calculations assigns the 
result of $command{foo} to a *scalar* variable, the result of the subroutine
should be a single value - the result. However, in parse_all, the result of
doing $command{foo} is assigned to an *array*. In this case, the subroutine
should return two or more values: a string for vurl to say, and a manner in
which to say it.

Use the wantarray inbuilt variable to find out what to return. You can return
a set of things to do (a la glomp and poke) if we want an array, or a single
thing if we don't.

if(wantarray) {
	return ['string', 'MSG'];
}
else {
	return 'string';
}

That way, functions like !add can return just the value for parse_calculations
to use in situ (because parse_calculations doesn't want an array).

Confused? Good. Regardless of how it works, know this: where wantarray is 
Perl true, return an array containing all the things you want vurl to do; where
it is false, return a single value that would make sense when put in a sentence.

Your array return value should look like this:

return (wantarray) ? 
( [ "vurls $person", "ACTION"],
  [ "lol pwned",     "MSG"   ],
  ...
)
: "a vurled $person";

Each bracketed value is an anonymous array reference. Thus you return an array
of arrays. The outer array (specified by parentheses) is iterated over, in
order, by the script. Each item is dereferenced; the first item is what vurl
says, and the second is how she says it.

Note that the "else" of the tertiary conditional is a single value. This is
what you should return in that situation.

For simplicity's sake, you can just return the string you want vurl to say
if the command type is MSG. This is done a lot in the maths functions, wherein
we don't check wantarray and just return the result. Default behaviour is to
just say what's returned if the return value is not an array ref. Also remember
that just because wantarray is true it doesn't mean you have to *provide* an 
array. Perl is quite capable of assigning a single returned value to an array.

sub add {
	my ($a, $b) = split ' '; # split $_
	return $a+$b;
}

The above will work regardless of whether someone says !add 2 3 or %(!add 2 3).

REMEMBER: only ! commands need to be done like this. Subroutines that are used
to compute variables, for example, don't. They will only ever be used in scalar
context. !say &(everyone) will compute &(everyone) in scalar context and then
pass the resultant string to $command{say}, which may return either a list of
commands if it's vurl doing it, or a single value if in %(). So the result of
!say %(!say &(everyone)) is that first &(everyone) is replaced with a string (a
scalar function); then %(!say ... ) (which is big now) is replaced with the
SCALAR result of !say ...; then !say [that result] is parsed as a vurl command,
and thus returns its array version, which vurl does.

Capische?

#===============================
# Arrays and hashes
#===============================

Note that the hashes are named in the *singular*. This is for readability: when
you reference it, it looks like
  $session_var{target}
that is to say, when you reference it, you're referencing a single var from it.
When you use it in a for, your plural will be the "keys" in
  for (keys %session_var)
Arrays remain plural since they are a set and are thus likely to be used in a
plural context.

  %command
    contains all commands. The syntax is command => { 'sub' => \&sub, [usage => 'usage] },
    the usage bit being optional. This will match !command and the sub will be passed
    the rest of the message, excluding the space after !command.

  %alternative
    is a set of keys that point to the actual command to run if matched. You may use
    a regex or simply a string as the key value. A !command will be tested against
    this array first and replaced with the command it points to.

  %constant 
    is easy and just replaces the big bunch of my V_FOOs that determine how the
    script behaves.

  %session_var 
    is set up on every message. Basically it's all the stuff that's
    relevant to a particular message, i.e. the server, channel, nick and whatever
    else. It's populated in the message handler(s).

  %variable 
    is, as mentioned, where all the variables are stored, including user
    variables. ans goes in here.

  %global_var
    is for globals like home and constants like pi, rather than for constants
    that determine the behaviour of the script.

  %autoresponse
  	is trigger => response. Check out how to use it in sub message. The trigger
    is a regex - you can save a regex in a variable using $foo = qr//;.

  @random_responses
    is a bunch of stuff to say on any message that doesn't trigger something else.

  @maths_fns, @traditional_fns, @utility_fns and @script_fns
    list the relevant hash keys for those groups. This creates a set for each group
    programatically, and creates an order for them to be reported in.

#########################
OTHER STUFF
by everyone
#########################

Caveats:
Bear in mind that if there's an error in the script, it won't auto-load!
Doesn't respond to rum in /me actions <-- sorted, love benmachine

		!do 5 !say &&(random_nick)
			will say 5 different random nicks, because they !do command passes unevaluated &(random_nick) to each !say command.
	Likewise, when adding variables to !verb or !adverb, or to !ascript, remember to use &&(foo) if you want the variable &(foo)
		to be evaluated during execution (e.g. "!ascript blip: !say This channel is called &&(chan)")
	Otherwise, the variable is evaluated when the script is added, and the value _at time of script creation_
		is saved - for example:
		!ascript blop: !say This script was originally created in &(chan)

TODO:
	Someone check these TODOs.

	Make a config file, and a command to reload the config from this file, so changing config variables doesn't require restarting vurl? (make sure this isn't a security risk; at the moment, only manually restarting vurl can make config changes)

 	Do a proper calculator, perhaps - RPN? (Do we still need to do this?) (arguably yes: although the functionality can be replicated it takes a whole lot of %()s)
	Have a generalised maths function which stores into $user_vars{'ans'}, and distinguish between functions inside this general one? (Likewise this - we can embed the functions now and use !store)

	Take input from privmsg and action events, feed them through separate parsers, and then into a single command interpreter function (What? Love from al)
	
	What does the HASH in user_vars do? (Where?)
	Is signal_emit safe? (I think so...) (Is your mum safe?)
	Upon connect, run /init

 <benmachine> oh tim you know what would be cool, ?(1,2,3) picks a random element of the list (!decide does this now - Al)

 To use delays: "<Erasmus> You need this at the top: "use Irssi qw(timeout_add_once);" and it works like: "timeout_add_once('20000', 'chal', $server);"
 		where 20000 is the number of milliseconds (so this is 20 seconds), chal is the subroutine to run, and $server is the data to pass to the subroutine. K?" (benmachine: you can see this working in sober_timeout now)

	Some things check if !defined $arg where $arg can frequently be defined but empty
	Some things get around this by checking if !$arg but try !criw 0
=cut

use strict;
use vars qw($VERSION %IRSSI);
use POSIX qw(ceil floor mktime);
use Safe; 

## use Math; ## ?

use Irssi qw(timeout_add_once timeout_remove);
use Data::Dumper;
use List::Util qw( first );
use Switch;

$VERSION = '2.1.6'; ## a bit more hammertime. also it now gets rid of a ? at the end of a !decide if there is one, also something about %alternatives
	# and, restock and er... look just diff it okay
%IRSSI = (
	authors	=> 'Tim Goodwyn',
	contact => 'tim.goodwyn@gmail.com',
	name	=> 'vurl',
	description => 'The vurl bot',
	license => 'mine. all mine. you can use it if you ask nicely',
);

## Constants and globals (these control the options for the bot)
my %constant = (
	# Determines whether the !eval command is enabled (this is set to 0 by default)
	V_EVAL_ENABLED			=> 1,
	# Whether or not the !np (now playing) command for rhythmbox is enabled
	V_NP_ENABLED			=> 0,
	V_DO_ENABLED			=> 1,
	V_RSCRIPT_ENABLED		=> 1,
	# Whether or not !quit is enabled (CAREFUL!)
	V_QUIT_ENABLED			=> 0,
	# Whether the caption script is enabled
	V_CAT_ENABLED			=> 0,
	V_AUTOINVITE_ENABLED	=> 1,
	V_EEK_ENABLED			=> 1,
	V_DECIDE_ENABLED		=> 1,
	V_DECIDE_SILENCED		=> 0,
	V_RANDOMKICK_ENABLED	=> 1,
	V_BEEP_ENABLED			=> 0,
	# Beware, this has a custom `` call, and I don't guarantee its security. _Disable this if you are not me__
	V_OC_ENABLED			=> 0,
	V_NICK_ENABLED			=> 0,
	V_PARROT_ENABLED                => 1,
	# The IP of the computer vurl is on (set to localhost at the moment)
	V_MY_IP 				=> '127.0.0.1',
	# Whether vurl announces maths function results
	V_QUIET_MATHS			=> 0,
	# Variables to govern the behaviour of drunken vurl
	V_DRUNK_LOOP_DIVISOR            => 10,
	V_DRUNK_MAGNITUDE_DIVISOR       => 10,
	# probability of no u
	V_NO_U_RATIO			=> 0.5,
);

# These are the hostnames of the people who own vurl. These people can use !eval and suchlike, so ensure only trusted people match the pattern okay
my @V_HOSTNAME_ENDINGS = (
	'@nw-A9C23401.net', # nexusnet autohostmask
	'badger@satgnu\.net',
	'@unaffiliated/asema',
	'@unaffiliated/kalir',
	'~detasund@*',
	'~zetsubou@*',
	'@unaffiliated/quairel',
	'@tremulous/developer/benmachine',
);	
	## There might be a problem with putting vurl's hostname on the list: vulnerability with /msg?
	## mwa deems *@satgnu.net to be trustworthy :P

my %global_var = (
	home            => '/home/badger',
	script_path     => '.irssi/scripts',
	adverbs_file    => 'adverbs.txt',
	verbs_file      => 'verbs.txt',
	scripts_file    => 'vscript.txt',
	dictionary      => '/usr/share/dict/british-english',
	pi              => 4*atan2(1,1),
	e               => exp(1),
	yarrs           => [ qw( Y'arr Yarrrr Arr! R Ooarrr Yarr Aharr!) ],
	hans		=> [ qw( tanks bombs helicopters nukes) ],
	msgs_between_warks => 5,
	max_do	        => 10,
	max_dice        => 100,
	wark_again      => {},
	parroting       => {},
);

## Load adverb/verb numbers.
{
	open ADVERBS, "<", "$global_var{home}/$global_var{script_path}/$global_var{adverbs_file}";
	my @adverbs = <ADVERBS>;
	chomp @adverbs;
	$global_var{num_adverbs} = scalar @adverbs;
	close ADVERBS;

	open VERBS, "<", "$global_var{home}/$global_var{script_path}/$global_var{verbs_file}";
	my @verbs = <VERBS>;
	chomp @verbs;
	$global_var{num_verbs} = scalar @verbs;
	close VERBS;

	open SCRIPTS, "<", "$global_var{home}/$global_var{script_path}/$global_var{scripts_file}";
	my @scripts = <SCRIPTS>;
	chomp @scripts;
	$global_var{num_scripts} = scalar @scripts;
	close SCRIPTS;
}

my %session_var = (
	server          => undef,
	channel         => undef,
	message_count   => 0,
	rum             => 500000,
	drunk           => 0,
	sober_timeout	=> undef,
	ans             => 0,
	#BattleCON stuff
	first_player    => undef,
	first_move      => undef,
	second_player   => undef,
	second_move     => undef,
	trap            => undef,
	env_coords      => [],
	env_tokens      => [],
	arena_channel   => "##arena",
);

my %alternative = (
#  qr/regex/ => key to %command
#  you can use a string instead of a regex,
#  but it will be used as though you had put it
#  in a regex - not using eq
	qr/lo+ng/  => 'long',
	qr/la+ar/  => 'laar',
	qr/^g$/    => 'google',
	qr/^w$/    => 'wikipedia',
	qr/^wiki$/ => 'wikipedia',
	qr/^u$/    => 'uncyclopedia',
);

my %command = (
#  !command			=> {
#  		'sub' => subroutine reference,
#  		usage => usage string,
#  	},
# Note that bareword hash keys are allowed, but sub will be wrongly
# translated and so has to be quoted.

# ==================
# Old-fashioned, tried-and-tested, country vurl
# ==================
	vurl            => {
		'sub' => \&vurl,
		usage => "!vurl [nick]",
	},
	adverb          => {
		'sub' => \&add_adverb,
		usage => "!adverb somethingly",
	},
	verb            => {
		'sub' => \&add_verb,
		usage => "!verb somethings",
	},
	draw            => {
		'sub' => sub { return [qq(eeeee), "KICK"]; },
		usage => "With eeeee in the room, !draw",
	},
	coffee          => {
		'sub' => \&coffee,
		usage => "!coffee [nick]",
	},
	rum		=> {
		'sub' => \&rum,
		usage => "!rum",
	},
	binge           => {
		'sub' => \&binge,
		usage => "!binge",
	},
	restock					=> {
		'sub' => \&restock,
		usage => "!restock",
	},
	lime            => {
		'sub' => \&lime,
		usage => "!lime [nick]",
	},
	decide          => {
		'sub' => \&decide,
		usage => "!decide {dilemma|option or option[ or option] ...}",
	},
	cookie          => {
		'sub' => \&cookie,
		usage => "!cookie [nick]",
	},
	shoot           => {
		'sub' => \&shoot,
		usage => "!shoot [nick]",
	},
	criw            => {
		'sub' => \&criw,
		usage => "!criw [nick]",
	},
	glomp           => {
		'sub' => \&glomp,
		usage => "!glomp [nick]",
	},
	poke            => {
		'sub' => \&poke,
		usage => "!poke [nick]",
	},
	bla             => {
		'sub' => \&bla,
		usage => "!bla",
	},
	foo		=> {
		'sub' => \&foo,
		usage => "!foo",
	},
	laar            => {
		'sub' => \&laar,
		usage => "!laar",
	},
	melon           => {
		'sub' => \&melon,
		usage => "!melon [nick]",
	},
	celebrate       => {
		'sub' => \&celebrate,
		usage => "!celebrate",
	},
	blurge          => {
		'sub' => \&blurge,
		usage => "!blurge",
	},
	spleen          => {
		'sub' => \&spleen,
		usage => "!spleen",
	},
	long            => {
		'sub' => \&long,
		usage => "!long somethingwithavowelinit",
	},

	test            => {
		'sub' => \&test,
		usage => "!test",
	},
	flib		=> {
		'sub' => \&flib,
		usage	=> "!flib",
	},
	'<3'            => { 
		'sub' => sub { my $n = shift||$session_var{nick}; 
					return (wantarray) ? "<3 $n" : "$n (<3)"; }, 
		usage => '!<3 someone',
	},
	nick		=> {
		'sub' => \&nickchange,
		usage => "!nick foo",
	},
	sweedee		=> {
		'sub' => sub { return "Sweedee? Sweedee Sweedee! O_O"; },
		usage => "!sweedee",
	},
	eek     => {
		'sub' => \&eek,
		usage => "!eek",
	},
# ==================
# Smart, city vurl with edjumucation in maffs
# ==================
	'rand'          => {
		'sub' => \&var_rand,
		usage => "!rand [[min] max]",
	},
	'roll'		=> {
		'sub' => \&roll,
		usage => "!roll [repeat]#[dice]d[sides]+[modifier]"
	},
	'rollstats'	=> {
		'sub' => \&dice_stats,
		usage => '!rollstats'
	},
	'avroll'	=> {
		'sub' => \&roll_average,
		usage => "!avroll [dice]d[sides]+[modifier]"
	},
	'define'	=> {
		'sub' => \&define,
		usage => "!define foo"
	}, 
	e               => {
		'sub' => \&e,
		usage => "!e [x=1]",
	},
	z               => {
		'sub' => \&z,
		usage => "!z x [max. iterations=100]",
	},
	log		=> {
		'sub' => \&log,
		usage => "!log x",
	},
	add             => {
		'sub' => \&add,
		usage => "!add [x=&(ans)] y",
	},
	sub           => { 		## This appears to work, so hey-ho
		'sub' => \&subtract,
		usage => "!sub [x=&(ans)] y",
	},
	mul             => {
		'sub' => \&mul,
		usage => "!mul [x=&(ans)] y",
	},
	div             => {
		'sub' => \&div,
		usage => "!div [x=&(ans)] y",
	},
	pow             => {
		'sub' => \&pow,
		usage => "!pow [x=&(ans)] y",
	},
	int             => {
		'sub' => \&to_int,
		usage => "!int x",
	},
	sin             => {
		'sub' => \&mysin,
		usage => "!sin x",
	},
	cos             => {
		'sub' => \&mycos,
		usage => "!cos x",
	},
	tan             => {
		'sub' => \&mytan,
		usage => "!tan x",
	},
	quad            => {
		'sub' => \&quad,
		usage => "!quad a b c",
	},
	dot             => {
		'sub' => \&dot,
		usage => "!dot (ax, ay, az) (bx, by, bz)",
	},
	cross           => {
		'sub' => \&cross,
		usage => "!cross (ax, ay, az) (bx, by, bz)",
	},
# ==================
# Immigrant vurl, with a good work ethic.
# ==================


	'do'            => {
		'sub' => \&scriptdo,
		usage => "!do n !foo"
	},
	
	'if'            => { 
		'sub' => \&scriptif,
		usage => "!if foo {!=|==|lt|<|gt|>|eq|ne} bar: <command>[: <command>]"
	},
	lscripts        => {
		'sub' => \&lscripts,
		usage => "!lscripts"
	},
	lscript         => {
		'sub' => \&lscript,
		usage => "!lscript <scriptname>"
	},
	rscript         => {
		'sub' => \&rscript,
		usage => "!rscript <scriptname>"
	},
	ascript         => {
		'sub' => \&ascript,
		usage => "!ascript <name>: <content>"
	},
# ==================
# Obedient vurl knows her masters.
# ==================
	join            => {
		 sub  => sub {
	       	 $session_var{server}->command("JOIN ".shift) if trusted_user();
				 },
		usage => "!join <channel>"
	},
	connect         => {
		 sub  => sub {
		       $session_var{server}->command("CONNECT ".shift) if trusted_user();
					 } ,
		usage => "!connect <server>"
	},
	set             => {
		sub   => sub {
					my ($var, $val) = split /\s/, $_[0], 2;
					return "No :(" unless trusted_user();
					if (exists $global_var{$var}) {
					 	$global_var{$var} = $val;
						return "k.";
					}
					if (exists $session_var{$var}) {
						$session_var{$var} = $val;
						return "k.";
					}
					if (exists $constant{$var}) {
						$constant{$var} = $val;
						return "k.";
					}
					return "Not a special variable. Use !store ps.";
				},
			usage => "!set var val",
		},


# ==================
# Upper-class vurl, ever helpful.
# ==================
	say       => {
		'sub' => sub { my $msg = shift;
									 if ($msg =~ m/^(#+\S+)/ and trusted_user()) {
									 	 $session_var{target} = $1;
										 $msg =~ s/^\Q$1\E\s+//g;
									 }
									 $msg =~ s|^/me || ? [$msg, 'ACTION' ] : $msg;
								 },
		usage => "!say foo", # :\/
	},
	version         => {
		'sub' => sub { return $VERSION; },
		usage => "!version",
	},
	uptime          => {
		'sub' => \&uptime,
		usage => "!uptime",
	},
	store           => {
		'sub' => \&store,
		usage => "!store var_name value",
	},
	eval            => {
		'sub' => \&evaluate,
		usage => "!eval string",
	},
	vars            => {
		'sub' => \&vars,
		usage => "!vars",
	},
	maths           => {
		'sub' => \&maths,
		usage => "!maths",
	},
#	utilities       => {
#		'sub' => \&utilities,
#		usage => "!utilities",
#	},
	auth            => {
		'sub' => \&auth,
		usage => '!auth',
	},
	vurlisms        => {
		'sub' => \&vurlisms,
		usage => "!vurlisms",
	},
#	scripting       => {
#		'sub' => \&scripting,
#		usage => "!scripting",
#	},
#	commands        => {
#		'sub' => \&commands,
#		usage => "!commands",
#	},
	randomkick      => {
		'sub' => \&randomkick,
		usage => "!randomkick",
	},
	wikipedia       => {
		'sub' => \&wikify,
		usage => "!wikipedia|!wiki|!w subject",
	},
	uncyclopedia    => {
		'sub' => \&uncyclopedia,
		usage => "!uncyclopedia|!u subject",
	},
	google          => {
		'sub' => \&google,
		usage => "!google|!g subject",
	},
	srd         => {
		'sub' => \&srd,
		usage => '!srd subject',
	},
	define          => {
		'sub' => \&define,
		usage => '!define|!def word',
	},
	war           => {
		'sub' => \&warfighter,
		usage => '!war',
	},
	devastation   => {
		'sub' => \&devastationfighter,
		usage => '!devastation',
	},
	battlecon     => {
		'sub' => \&battlecon,
		usage => '!battlecon',
	},
	bastion       => {
		'sub' => \&bastion,
		usage => '!bastion',
	},
	ftl           => {
		'sub' => \&ftl,
		usage => '!ftl',
	},
	tasen         => {
		'sub' => \&tasen,
		usage => '!tasen',
	},
	komato        => {
		'sub' => \&komato,
		usage => '!komato',
	},
	kalir         => {
		'sub' => \&kalir,
		usage => '!kalir',
	},
	hanftl        => {
		'sub' => \&hanftl,
		usage => '!hanftl',
	},
	sober         => {
		'sub' => \&sober_up,
		usage => '!sober',
	},
	pair          => {
		'sub' => \&pair,
		usage => '!pair [move]',
	},
	reveal        => {
		'sub' => \&reveal,
		usage => "!reveal",
	},
	settrap       => {
		'sub' => \&settrap,
		usage => "!settrap [trap]",
	},
	showtrap      => {
		'sub' => \&showtrap,
		usage => "!showtrap",
	},
	cleartrap     => {
		'sub' => \&cleartrap,
		usage => "!cleartrap",
	},
	setenviro => {
		'sub' => \&setenviro,
		usage => "!setenviro [position] [token]",
	},
	environment => {
		'sub' => \&environment,
		usage => "!environment",
	},
	setarena      => {
		'sub' => \&setarena,
		usage => "!setarena",
	},
);

my @maths_fns = qw(
	e    z    log  add   sub 
	mul  div  rand quad  sin 
	cos  tan  pow  dot   cross 
	int
);

my @utility_fns = qw(
	store     uptime     maths      utilities 
	vurlisms  scripting  commands   vars
	eval      say        wikipedia  google
	war       battlecon  bastion    devastation
	ftl       tasen      komato     uncyclopedia
	kalir     hanftl     sober      pair
	reveal    settrap    showtrap   cleartrap
	setenviro environment
	setarena
);

my @traditional_fns = qw(
	vurl    adverb     verb        coffee 
	lime    criw       glomp       poke
	decide  cookie     shoot       
	melon   celebrate  blurge      spleen
	bla     long       randomkick  laar
	foo
);
my @script_fns = qw(
	do	if
);

my %variable = (
	everyone    => sub { my @nicks = nicklist($session_var{server},$session_var{target});
	                     return (wantarray) ? @nicks : join (", ", @nicks);
	                   },

	random_nick => sub { my @e = nicklist($session_var{server},$session_var{target}); return $e[int rand($#e)]; },
	ans         => 0,
);

my %autoresponse = (
	qr{^:\\/$}
		=> sub { 
			$global_var{wark_again}->{$session_var{target}} = $global_var{msgs_between_warks}
				if(!defined $global_var{wark_again}->{$session_var{target}});

			my $wark_again = $global_var{wark_again}->{$session_var{target}};
			if($wark_again >= $global_var{msgs_between_warks}) {
				$global_var{wark_again}->{$session_var{target}} = 0;
				return ':\/';
			}
		},
	qr/(?:\s|^)(?:y'?)?ar+(?:\s|$)/i
		=> \&yarr,
	qr/(\boh de[ea]r\b)+/i
		=> \&ohdear,
	qr/^!help$/ => sub { return 'http://badger.satgnu.net/vurlhelp.txt' },
	qr/dears/ => sub { return 'mhmhmhmhm, dears' },
	qr/mhm(hm)+/ => sub { return 'mhmhmhmhm, dears' },
	qr/^:$/
		=> sub { return ':'; },
	qr/^tanks$/i 
		=> \&han,
	qr/^helicopters$/i
		=> \&han,
	qr/^bombs$/i
		=> \&han,
	qr/^nukes$/i
		=> \&han,
	qr/^this is spa+rta+/i
		=> sub { return ["$session_var{nick} kicked down an oversized well", "KICK"]; },
  	qr/\^_+\^/
		=> sub { return '^_^'; },
	qr/(^|\W)rum($|\W)/i
		=> \&rum_autoresponse,
	qr/^marvin/i
		=> sub { return "lol emo"; },
	qr/^o rly\?*/i
		=> sub { return "ya rly"; },
	qr/^ya rly!*/i
		=> sub { return "no wai!"; },
	qr/^goodnight,? vurl(?:ybrace)?$/i
		=> sub { return ["$session_var{nick} sleep well", "KICK"]; },
	qr/hi,? vurl(?:ybrace)?/i
                => sub { return ["waves", "ACTION"]; },
        qr/^go away,? vurl(?:ybrace)?$/i
                => sub { return "B)" if ($session_var{nick} eq 'PercivalPale');
			 return ["of course", "PART"]; },
	qr/^stop[!\.]?$/i
		=> sub {
				return "hamertijd!" if (int(rand(17)) == 0); ## Dutch 1/17 of the time
				return "hammertime!"; },
	qr/^halt[!\.]?$/i
		=> sub { return "hammerzeit!" },
	qr/^arret[!\.]?$/i
		=> sub { return "temps de marteau!" },
	qr/^paranse[!\.]?$/i
		=> sub { return "tiempo de martillo!" },
	qr/^siste[!\.]?$/i
		=> sub { return "tempus mallei!" },
	qr/^fermi[!\.]?$/i	## i think this is right, possibly
		=> sub { return "tempo di martello!" },
	qr/^lopeta[!\.]?$/i	## thanks to pararara; finnish
		=> sub { return "vasara-aika!" },
	qr/^poczekaj[!\.]?$/i   ## polish, thanks to jocke pirat
		=> sub { return "mlotekczas!" },
	qr/^fairgreip[!\.]?$/i  ## gothic - awesome huh?
		=> sub { return "hamara aiws!" },
	# greek:
	#qr/^testtest$/i
	#qr/^\x{03C3}\x{03C4}\x{03B1}\x{03BC}\x{03B1}\x{03C4}\x{03B7}\x{03C3}\x{03B5}\x{03B9}!?\.?$/i
	#qr/\x{03C3}/i
	#	=> sub { return "\x{03BF} \x{03C7}\x{03C1}\x{03BF}\x{03BD}\x{03BF}\x{03C2} \x{03C4}\x{03B7}\x{03C2} \x{03C3}\x{03C6}\x{03C5}\x{03C1}\x{03B1}\x{03C2}" },
	qr/^mud$/i
		=> sub { return "kip!"; },
	qr/^kip!?$/i
		=> sub { return "mud"; },
	qr/^vurl was eaten by a grue/i
		=> sub { return ( [qq(dies horribly),             "ACTION" ],
		                  [qq(aaaarrrrghh!!! *crunch*),   "PART"   ] ); },
	qr/^(no,? )?u$/
		=> sub { return 'no u' if rand() < $constant{V_NO_U_RATIO}; },
	qr/^\/me flib$/
		=> sub { return '!test' },
	qr/^\/me test$/
		=> sub { return '!flib' },
	qr/^\/me pours tea on vurl$/
		=> sub { return [qq(doesn't like tea), "ACTION"] },
	qr/(^|\W)homre($|\W)/i
		=> sub { return "In trouble!  DRIVE!  DRIVE!  DRIVE!" },
);

#my @random_responses = (
#	\&cookies_and_cream,
#);

## User-defined variables - is there any possible exploit here? :S
## - Just make sure you interpolate the supplied variable. I recommend qq(). love from al
my %user_var = ( '_' => '&(_)' );

## ------------------------------------------
##  *subs*
##  Subs below this line please. Let's keep it tidy.
## ------------------------------------------

sub trusted_user
{
	my $server = $session_var{server};
	my $target = $session_var{target};
	my $person = shift || $session_var{nick};
	my $host = $session_var{host};
	#my $channel = $server->channel_find($target) || return;
	#my $nick = $channel->nick_find($person);
	#my $host = $nick->{'host'};

	for (@V_HOSTNAME_ENDINGS) {
		return 1 if $host =~ m/$_/;
	}
}

sub is_on_chan {
	my ($name, $blaat) = split ' ', shift;
	return 0 if $blaat;

	$name = lc($name);

	return scalar grep {lc($_) eq $name} nicklist();
}

# pass this a number please
sub plural {
	my $arg = shift;
	return ($arg != 1 ? "s" : "") if($arg =~ m/^[0-9]+$/);
	return "";
}

sub drunken
{
	return drunken_custom(shift, $session_var{drunk});
}

sub drunken_custom
{
	my ($arg, $drunk) = (shift, shift);
	my $len = length($arg);
	$drunk *= ($len / 20);
	for(my $i = 0; $i < ($drunk / $constant{V_DRUNK_LOOP_DIVISOR}); $i++)
	{
		my $index = int(rand($len));
		my $offset = (rand(2) - 1) * ($drunk / $constant{V_DRUNK_MAGNITUDE_DIVISOR});
		$offset = $len - $index - 1 if($index + $offset >= $len);
		$offset = 0 - $index if($index + $offset < 0);
		my $string = substr($arg, 0, $index) . substr($arg, $index + 1);
		$arg = substr($string, 0, $index + $offset) . 
			substr($arg, $index, 1) . 
			substr($string, $index + $offset);
	}
	return $arg;
}

sub sober
{
	$session_var{drunk} -= 1;
	if($session_var{drunk} > 0)
	{
		$session_var{sober_timeour} = timeout_add_once('20000', 'sober', 0);
	}
}

sub var_rand {
	my $arg = shift;
	my $float = (index($arg, ".") > 0);
	my ($max, $min, $extra) = reverse(split(/\s*,?\s+/, $arg));
	$max = ($float) ? 1 : 10 if !defined $max;
	return "what" if length $extra;
	my $r = rand($max - $min);
	$r = int($r) if !$float;
	return $r + $min;
}

sub roll_dice {
	my ($dice, $sides, $mod) = @_;
	my $res = 0;
	$res += int(rand($sides)) + 1 for (1..$dice);
	return $res + $mod;
}

sub dice_stats {
	my $avg;
	my $samplesize = 10000;
	$avg += roll_dice(3,6,0) for (1..$samplesize);
	$avg /= $samplesize;
	return "3d6 average: $avg over $samplesize rolls";
}

sub roll {
        my ($times, $dice, $sides, $mod) = (1, 1, 20, 0);
	my $prefix = $session_var{nick};
        my @rolls;
        # Note ^ and $ here - so there must be nothing else in the
        # matching string
        unless(shift =~ m/^(?:(\d+)#)?(?:(\d+)d)?(?:(\d+))?(?:([+-]\d+))?$/)
        {
                return "No match, sorry";
        }
		
        $prefix .= ': (';
        if(defined $1) {
                $times = $1;
                return "too many numbers :(" if $times > 200;
                $prefix .= "${times}#";
        }

        if(defined $2) {
                $dice = $2;
                return "too many dice :(" if $dice * $times > 1000000;
        }
        $prefix .= "${dice}d"; # always display number of dice

        if(defined $3) {
                $sides = $3;
        }
        return (wantarray ? "You are a charlatan." : "bees") if $sides < 1;
        $prefix .= "$sides"; # similarly sides

        if(defined $4) {
                $mod = $4;
                $prefix .= sprintf("%+d", $mod); # always put a sign
        }
        $prefix .= ') ';

	push @rolls, roll_dice($dice,$sides,$mod) for (1..$times);

        return ((wantarray ? $prefix : "") . join ' ', @rolls);
}

sub roll_average {
	my ($times, $dice, $sides, $mod, $res, $response);
	if(shift =~ m/(?:(\d+)#)?(?:(\d+)d)?(?:(\d+))?(?:\+(\d+))?/)
	{
		$times = (defined $1) ? $1 : 1;
		$dice  = (defined $2) ? $2 : 1;
		$sides = (defined $3) ? $3 : 20;
		$mod   = (defined $4) ? $4 : 0;
	}

	if((defined $1) && (defined $4)) {
		$response = "(${times}#${dice}d${sides}+${mod}) - ";
	}
	elsif(!defined $1) {
		$response = "(${dice}d${sides}+${mod}) - ";
	}
	elsif(!defined $4) {
		$response = "(${times}#${dice}d${sides}) - ";
	}
	elsif((!defined $1) && (!defined $4)) {
		$response = "(${dice}d${sides}) - ";
	}
	for(1..$times) {
		$res = 0;
		for(1..$dice) {
			my $throw = int(rand($sides)) + 1;
			$throw = $sides * 0.5 if($throw < $sides * 0.5);
			$res += $throw;
		}
		$res += $mod;
		$response .= " $res"
	} 
	return $response;
}

#sub define {
#  my ($arg) = @_;

#  my ($remote,$port,$proto,$url,$nextm,$line,%escapes,$iaddr,$paddr,$headers,$nl,$crlf,$stuff,@status,$func);

#  $remote = "www.google.com";
#  $url = "/search?q=define:$arg";

#  for (0..255) { $escapes{chr($_)} = sprintf("%%%02X", $_); }
#  $url =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;
#  $url =~ s/ /+/g;
#  $port = "80";

#  $iaddr = gethostbyname($remote) or return "Host $remote is not resolvable";
#  $paddr = sockaddr_in($port,$iaddr);

#  $proto = getprotobyname('tcp');

#  socket (SOCKCHECK,PF_INET,SOCK_STREAM,$proto) or die "socket: $!";
#  connect (SOCKCHECK, $paddr) or return "connect: $!";

#  undef $headers;
#  $nextm = 0;
#  $headers .= "User-Agent: vurl\n";
#  $headers .= "Host: www.google.com\n";
#  $headers .= "Connection: Close\n";

#  send (SOCKCHECK,"GET $url HTTP/1.1\n$headers\n\n",0);

#  $func = "No definitions found.";
#  while ($line = <SOCKCHECK>) {
#    chomp ($line);

#    if ($line =~ /<p>Definitions.+?<li>(.+?)(<li>|<br>)/i) {
#      $func = "$arg: $1";
#      $func =~ s/<.+?>//gi;
#      $func =~ s/&gt;/>/g;
#      $func =~ s/&lt;/</g;
#      $func =~ s/&quot;/"/g;
#      $func =~ s/&amp;/&/g;
#      last;
#    }
#}

sub vurl {
	my $nick = shift || $session_var{nick};

	# !vurl me and there is no one called Me in the chan
	$nick = $session_var{nick} if (lc($nick) eq 'me' and !(grep { lc($_) eq 'me' } nicklist()));
	my $adverb = adverb();
	my $verb   = verb();
	$verb .= " &(_)" unless $verb =~ m/(^|[^&])&\(_\)/;

	my $response = $verb;

	# If the adverb begins with 's then put it after the vurlee
	if($adverb =~ m/^'s/) { $response =~ s/(^|[^&])&\(_\)/\1$nick$adverb/g; } 
	# Otherwise put it at the end
	else                  { $response =~ s/(^|[^&])&\(_\)/\1$nick/g; 
	                        $response .= " $adverb"; }

	$response =~ s/&&\(_\)/&\(_\)/g;

	$response = parse_variables($response);
	$response = parse_calculations($response);
	$response =~ s/\s+([,';.])/\1/g; #remove space before punctuation
	$response = drunken($response);

	return [$response, "ACTION"] if wantarray;
	return "a vurled $nick";
}

sub adverb {
	open ADVERBS, "<", "$global_var{home}/$global_var{script_path}/$global_var{adverbs_file}";
	my @adverbs = <ADVERBS>;
	chomp @adverbs;
	close ADVERBS;

	return $adverbs[int(rand($#adverbs))];
}

sub verb {
	open VERBS, "<", "$global_var{home}/$global_var{script_path}/$global_var{verbs_file}";
	my @verbs = <VERBS>;
	chomp @verbs;
	close VERBS;

	return $verbs[int(rand(scalar @verbs))];
}

sub decide {
	my $text = shift;
	$text =~ s/\?$//;

	return (wantarray)
		? ["is indecisive", "ACTION"] 
		: "indecisiveness"
		if !$constant{V_DECIDE_ENABLED};

	if(trusted_user($session_var{nick}))
	{
		return "Yes" if lc($text) eq "yes";
		return "No"  if lc($text) eq "no";
	}

	#print $text;
	my @opts = split / or /i, $text;
	my @facetiousness 
		= (scalar @opts == 2) 
		? ("Neither", "Both") : 
		  ("None of the above", "All ".scalar @opts."!");
  
	if (scalar @opts <= 1) { 
		$opts[0] = 'Yes';
		$opts[1] = 'No';
	}
	elsif (int(rand(100)) == 99) { return $facetiousness[0]; }
	elsif (int(rand(100)) == 0 ) { return $facetiousness[1]; }

#	if ($session_var{target} =~ m/^#/) {
#	return;
#	}

	return $opts[int(rand(scalar @opts))]; 
}

sub yarr {
	my @responses = @{$global_var{yarrs}};
	my $response = $responses[int rand($#responses)];

	return $response;
}

sub han {
       my @responses = @{$global_var{hans}};
       my $response = $responses[int rand($#responses)];

	return $response;
}

sub role {
        my @responses = @{$global_var{roles}};
        my $response = $responses[int rand($#responses)];
	return (wantarray) ? ["recommends $response", "ACTION"] : $response;
}

sub class {
        my @responses = @{$global_var{croles}};
        my $response = $responses[int rand($#responses)];
        return (wantarray) ? ["recommends $response", "ACTION"] : $response;
}

sub race {
        my @responses = @{$global_var{craces}};
        my $response = $responses[int rand($#responses)];
        return (wantarray) ? ["recommends $response", "ACTION"] : $response;
}

sub char {
        my @classes = @{$global_var{croles}};
	my @races = @{$global_var{craces}};
        my $chosenclass = $classes[int rand($#classes)];
	my $chosenrace = $races[int rand($#races)];
	my $response = $chosenrace;
	$response .= " ";
	$response .= $chosenclass; 
        return (wantarray) ? ["recommends $response", "ACTION"] : $response;
}

sub ohdear {
	my @ohdears = $session_var{text} =~ m/\boh de[ea]r\b/ig;
	my $deer = grep { /deer/ } @ohdears;
	my $total = scalar @ohdears;

	# one more (value doesn't get used)
	push @ohdears, ":(";

	return join " ", map { $_ = rand($total) < $deer ? "oh deer" : "oh dear" } @ohdears;
}


sub bacon { 
	my $args = $session_var{text};
	my $bacons = () = $args =~ m/bacon ?/ig;
	return "bacon " x ($bacons+1);
}

sub rum {
	my $rum = $session_var{rum};
	return drunken((wantarray) ? "($rum tots of rum left)" : 
		($rum > 1) ? "$rum tots of rum" : 
		($rum == 1) ? "one tot of rum" : "no rum");
}

sub rum_autoresponse {
	my $msg;
	if($session_var{rum} > 0)
	{
		$session_var{rum}--;
		$msg = drunken("/me hands $session_var{nick} some rum, because it isn't gone at the moment");
		my $msg_type = "MSG";
		$msg =~ s{/me\s+}{} and $msg_type = "ACTION";

		return [$msg, $msg_type];
	}
	$msg = drunken("/kick $session_var{nick} the rum is always gone, and so are you");
	my $msg_type = "MSG";
	$msg =~ s{/kick\s+}{} and $msg_type = "KICK";

	return [$msg, $msg_type];
}

sub binge {
  my $rum = $session_var{rum};
	return (wantarray) ? drunken("I've had enough :(") : "some restraint"
		if($session_var{drunk} > 50);
	if($rum >= 10)
	{
		my $amount = int(rand(9) + 1);
		$session_var{rum} -= $amount;
		$session_var{drunk} += $amount;
		timeout_remove($session_var{sober_timeout});
		$session_var{sober_timeout} = timeout_add_once('20000', 'sober', 0);

                my $msg = drunken("/me drinks $amount measures of rum, leaving $session_var{rum} measures left");
                my $msg_type = "MSG";
                $msg =~ s{/me\s+}{} and $msg_type = "ACTION";

		return wantarray 
			? [$msg, $msg_type] 
			: "a drunken binge";
	}
	else
	{
	  # <3 ternary
		return ($rum) ? drunken(wantarray ? "I'd better not, there's only $session_var{rum} left" : "some restraint") : drunken(wantarray ? "there isn't any :(" : "no rum");
	}
}

sub restock {
	return unless trusted_user();
	my $amount = int(rand(9) + 1);
	my $rum = $session_var{rum} += $amount;
  return (wantarray) ? "here, $amount tots o' rum (now there are $rum)" : "$amount tots o' rum (making $rum)";
}

sub coffee {
	my $person = shift || $session_var{nick};
	my $whattodo = 
		($person eq 'vurl') ? (wantarray) ? qq(purrs) : qq{coffee for vurl (thank you!)}
		                    : (wantarray) ? qq(gets some coffee for $person) : 
							                qq(coffee for $person)
	;
	$session_var{drunk} -= 10 if($person eq 'vurl');
	$session_var{drunk} = 0 if($session_var{drunk} < 0);

	return (wantarray) ? [$whattodo, "ACTION"] : $whattodo;
}

sub tea {
	my $person = shift;

	return ( (wantarray) ? [q(doesn't like tea),"ACTION"]
	                     :  q{tea (yuck!)} )
		if ($person eq 'vurl');

	return qq(tea for $person) unless wantarray;
	return;
}

sub lime {
	my $person = shift || $session_var{nick};

	return (wantarray) ? 
		[qq(pelts $person with limes. 'tis against the scurvy, don't y'know.), "ACTION"]
	:	"lots and lots of limes for $person"
	;
}

sub melon {
	my $person = shift || $session_var{nick};

	return (wantarray) ? 
		([qq(pelts $person with melons), "ACTION"])
	:	"+++MELON MELON MELON+++"
	;
}

sub uptime {
	my $ut = `uptime`;
	return $ut;
}

sub cookie {
	my $person = shift || $session_var{nick};

	return (wantarray)
		? [qq(magically finds a cookie and consumes it noisily), "ACTION"]
		: "a magic cookie"
		if $person eq $session_var{server}->{nick};

	return (wantarray) ? [qq(gives $person a cookie), "ACTION"] : "a cookie for $person";
}

sub shoot {
	my $person = shift or $session_var{nick};

	if(wantarray) {
		return ("shoot who?", "well, then...", ["$session_var{nick} ...you!", "KICK"])
			if !length $person;

		return [qq($session_var{nick} no u), "KICK"]
			if (lc($person) eq 'vurl');

		return [qq(shoots $person), "ACTION"];
	}
	else {
		return q(bullets! Everywhere!) if !length $person;

		return qq($session_var{nick} riddled with bullet holes) if (lc($person) eq 'vurl');

		return qq($person riddled with bullet holes);
	}
}

sub criw {
	my $person = shift;

	return ((wantarray) ? ["criws", "ACTION"] : "criw") if !length $person;

	return  (wantarray) ? [qq(criws at $person), "ACTION"] : "criwbaby $person";
}

sub poke {
	my $person = shift;
	my $target = $session_var{target};

	return ( (wantarray) ? [qq(pokes $session_var{nick}), "ACTION"]
	                     :  qq(a poked $session_var{nick}) )
			if (!defined $person or length($person) == 0);

	return ( (wantarray) ? 
		   ( [qq(pokes the grue),           "ACTION"],
		     [qq(gets eaten by the grue!),  "ACTION"],
		     [qq(dies horribly),            "ACTION"],
		     [qq(aaaarrrrghh!!! *crunch*),  "PART"  ],
		   )
		   : "a mauled vurl" ) 
		if (lc($person) eq 'grue');

	return (wantarray) ? [qq(pokes $person), "ACTION"] : qq(a poked $person);
}

sub glomp {
    my $person = shift || $session_var{nick};

    return ( (wantarray) ?
		   ( [qq(glomps the grue),               "ACTION"],
             [qq(gets eaten by the grue!),   "ACTION"],
             [qq(dies horribly),             "ACTION"],
             [qq(aaaarrrrghh!!! *crunch*),   "PART"  ],
    	   )
		   :  "a mauled vurl" ) 
		if (lc($person) eq 'grue');

    return (wantarray) ? [qq(glomps $person *^___^*), "ACTION"] : qq(a glomped $person *^___^*);
}

sub bla {
	my $length = shift || int(rand(5)) + 4;
	my $a = "";

	for (0..$length) {
		$a .= chr(int(rand()*26) + 97);
	}
	return $a;
}

sub foo {
	return "bar";
}

sub laar {
	open DICT, '<', $global_var{dictionary};
	my @words = <DICT>;
	close DICT;
	chomp @words;

	my $num_words = @words;
	my @what_to_say;
	for (0 .. int(rand(3)+3)) {
		push @what_to_say, $words[int(rand($num_words))];
	}

	my $msg = join ' ', @what_to_say;
	my $exc_str = '!' x int(rand(6)+1);#(! int(rand(3))) ? '!' x rand(6)+1 : '';
	my $q_str   = '?' x int(rand(6)+1);#(! int(rand(5))) ? '?' x rand(6)+1 : '';

	my $num_x_fail = int(rand(length($exc_str))-1);
	my $num_q_fail = int(rand(length($q_str))-1);
	$num_x_fail = 0 if $num_x_fail < 2;
	$num_q_fail = 0 if $num_q_fail < 2;

	my $fail = '1' x $num_x_fail;
	$exc_str =~ s/!{$num_x_fail}$/$fail/g;

	$fail = '/' x $num_q_fail;
	$q_str =~ s!\?{$num_q_fail}$!$fail!g; #fix vim syntax highlighting!
	my $exc_first = int(rand(2));

	if($exc_first) {
		$msg .= $exc_str;
		$msg .= $q_str;
	}
	else {
		$msg .= $q_str;
		$msg .= $exc_str;
	}

	return $msg;
}

sub celebrate {
	return (wantarray) ? [qq{celebrates. woo. <|:)}, "ACTION"] : "Hooraaayyy!!";
}

sub blurge {
	my ($messages, $verbs, $adverbs, $scripts) = (
		$session_var{message_count},
		$global_var{num_verbs},
		$global_var{num_adverbs},
		$global_var{num_scripts});
	return "$messages message". plural($messages) . " since last reload; " .
		"$verbs verb" . plural($verbs) . "; " .
		"$adverbs adverb" . plural($adverbs) . "; " .
		"$scripts script" . plural($scripts) . ".";
}

sub cat {
	#TODO: This. I can't be arsed.
	my ($pointsize, $url, $filename, $caption) = 
		m!([0-9]+|\s)\s?(http://.*/(.*\.(?:jpe?g|gif|png)))\s(.*)!gi
}

sub spleen {
	my $nick = &{$variable{random_nick}};
	return (wantarray) ? [qq(pokes $nick in the spleen), "ACTION"] : qq($nick\'s spleen);
}

sub long {
	my $text = shift;
	my $length = length $text;
	my @vowels = $text =~ /([aeiou])/gi;

	my $vowel_to_long = int(rand(scalar @vowels));

	my $longvowel = $vowels[$vowel_to_long] x (rand(5)+3);
	$text =~ s/((?:[aeiou][^aeiou]*){$vowel_to_long})([aeiou])(.*)/\1$longvowel\3/gi;
	#return ($length > 1) ? ucfirst(lc($text)) : $text;
	return $text;
}

sub test {
	return (wantarray) ? [qq(flib), "ACTION"] : qq(flib);
}

sub flib {
	return (wantarray) ? [qq(test), "ACTION"] : qq(test);
}

sub nickchange {
	my $arg = shift;
	my $nick = $session_var{nick};
	return "$nick, no :(" if !trusted_user($nick);

	return "No you'll break it :<" if $arg =~ m/[][\.\*]/;
#	what?
#	print Dumper(%session_var);
	$session_var{server}->command("NICK $arg");
}

sub eek {
	my $now = time();
	return "!eek disabled, to preserve the sanity of its users!"
		if !$constant{V_EEK_ENABLED};
	#                 s  m  h   d   m  y
	my $then = mktime(0, 0, 12, 2,  0, 109);
	my $eek = $then - $now;
	return "too late!" if $eek <= 0;
	my $days = int($eek / 86400);
	my $hours = int($eek / 3600) % 24;
	my $minutes = int($eek / 60) % 60;
	my $seconds = $eek % 60;
	return
		($days
			? "$days day" . plural($days) . ", "
			: "") .
		($days || $hours
			? "$hours hour" . plural($hours) . ", "
			: "") .
		($days || $hours || $minutes
			? "$minutes minute" . plural($minutes) . " and "
			: "") .
		# we know that at least some seconds remain
		"$seconds second" . plural($seconds) . 
		" left before Cambridge send out offers (ish).";
}

sub randomkick {
	my @nicks = nicklist($session_var{server},$session_var{target});
	my $nick = $session_var{nick};
	
	return (wantarray) ? ["$nick :(", "KICK"] : "$nick :(" if(!$constant{V_RANDOMKICK_ENABLED});
	return (wantarray) ? [$nicks[rand($#nicks)], "KICK"] : $nicks[rand($#nicks)];
}

sub e {
	my $operand = shift;
	
	if (!defined $operand or $operand eq q()) {
		$variable{ans} = $global_var{e};
		return $global_var{e};
	}

	return qq($operand is not a number :\() 
		if $operand !~ m/^\s*-?\d+(?:\.\d+)?\s*$/g;

	$variable{ans} = exp($operand);
	return $variable{ans};
}

sub z {
	$_ = shift;
	my ($operand, $iterations) = m/^(-?[0-9]+(?:\.[0-9]+)?)\s?([0-9]+)?$/g;

	return "i can has number pls?" 
		if (!defined $operand);

	$iterations = 100 if (!defined $iterations);
	my $z = 0;

	for (1..$iterations) {
		$z += 1/exp($operand*log($_));
	}

	$variable{ans} = $z;
	return $z;
}

sub log {
	$_ = shift;
	return ((wantarray) ? 'Value must be greater than 0' : 'NaN')
		if ($_ <= 0);

	my $ans = log($_);
	$variable{ans} = $ans;
	return $ans;
}

sub add { # FIXME: cba input validating these because they're no fun
	$_ = shift;
	my $total = 0;
	for(split " ")
	{
		$total += $_;
	}
	$variable{ans} = $total;
	return $total;
}

sub subtract { # FIXME: cba input validating these because they're no fun
	$_ = shift;
	my @ar = split(" ");
	my $total = shift(@ar);
	for(@ar)
	{
		$total -= $_;
	}
	$variable{ans} = $total;
	return $total;
}

sub string_mul {
	# Like the x operator, only more so
	my ($string, $multiplicand) = (shift, shift);
	my $output = $string;
	my $length = length($string);
	my $reverse = ($multiplicand < 0);
	$multiplicand = -$multiplicand if $reverse;
	my $part;

	return if !$multiplicand or !$length or !defined $string;

	$part = int($multiplicand);
	$output x= $part;
	$part = $multiplicand - $part;
	$output .= substr($string, 0, ceil($length * $part));

	return scalar(reverse($output)) if $reverse;
	return $output;
}

sub mul {
	my $string; 
	my $total = 1;
	my $length;
	for(split(" ", shift))
	{
		if($_ !~ m/^[+-]?[0-9\.]+$/)
		{
			return "what" if(defined $string);
			$string = $_;
			next;
		}
		$total *= $_;
	}
	return ($variable{ans} = $total) if !defined $string;

	return "nope" if $total > 100;
	return string_mul($string, $total);
}

sub div {
	$_ = shift;
	my ($a, $b) = split " ";
	return "what?" if($b !~ m/^[+-]?[0-9\.]+$/);
	return "universe a splode :(" if $b == 0;
	return string_mul($a, 1 / $b) if($a !~ m/^[+-]?[0-9\.]+$/);
	$a /= $b;
	$variable{ans} = $a;
	return $a;
}

sub pow {
	$_ = shift;
	my ($a, $b) = split " ";
	$a **= $b;
	$variable{ans} = $a;
	return $a;
}

sub to_int {
	return ($variable{ans} = int(shift));
}

sub quad {
	$_ = shift;
	my ($a, $b, $c) = m/(-?[0-9]+(?:\.[0-9]+)?) (-?[0-9]+(?:\.[0-9]+)?) (-?[0-9]+(?:\.[0-9]+)?)/g;
	if($a == 0)	{
		return "Error: quadratic can't have 0 as coefficient of x^2";
	}
	elsif($b*$b < 4*$a*$c)
	{
		my $re = -$b/(2*$a);
		my $im1 = +(sqrt(4*$a*$c - $b*$b))/(2*$a);
		return (wantarray) ? $a."x^2 + ".$b."x + $c = 0: Two complex roots: x = $re + $im1 i, or x = $re - $im1 i" : "$re + $im1, $re - $im1";
	}
	elsif($b*$b == 4*$a*$c)
	{
		my $soln = -$b/(2*$a);
		return (wantarray) ? $a."x^2 + ".$b."x + ".$c." = 0: One (repeated) real root: x = $soln" : $soln
	}
	else
	{
		my $solution1 = (-$b + sqrt(($b)*($b) - 4*$a*$c))/(2*$a);
		my $solution2 = (-$b - sqrt(($b)*($b) - 4*$a*$c))/(2*$a);
		return (wantarray) ? $a."x^2 + ".$b."x + ".$c." = 0: Two real roots: x = $solution1, or x = $solution2" : "$solution1, $solution2";
	}
}

sub mysin {
	$_ = shift;
	my ($arg, $degrees) = m/^(-?\d+(?:\.\d+)?)\s*(d)?$/gi;
	return "not a number!" if !length $arg;

	my $f = (defined $degrees) ? $global_var{pi} / 180 : 1;
	
	$variable{ans} = sin($arg * $f);
	return $variable{ans};
}	

sub mycos {
	$_ = shift;
	my ($arg, $degrees) = m/(-?\d+(?:\.\d+)?)\s*(d)?$/gi;
	return "not a number!" if !length $arg;

	my $f = (defined $degrees) ? $global_var{pi} / 180 : 1;
	
	$variable{ans} = cos($arg * $f);
	return $variable{ans};
}

sub mytan {
	$_ = shift;
	my ($arg, $degrees) = m/(-?\d+(?:\.\d+)?)\s*(d)?$/gi;
	return "not a number!" if !length $arg;

	my $f = (defined $degrees) ? $global_var{pi} / 180 : 1;
	
	if (($arg % 180) == 2*$global_var{pi}/$f) {
		return "The tan of ninety degrees doesn't exist (j/k lol)";
	}

	$variable{ans} = sin($arg * $f) / cos($arg * $f);
	return $variable{ans};
}

sub dot {
	# (-? \d+ (.\d+)? ), etc
	my ($string1, $string2) = shift =~ m/^\((.*)\) \((.*)\)$/;
	my (@vec1, @vec2);
	return "not two vectors" if (!$string1 || !$string2);
	foreach ($string1 =~ m/(-?\d+(?:\.\d+)?)[, ]?/g)
	{
		push @vec1, $_;
	}
	foreach ($string2 =~ m/(-?\d+(?:\.\d+)?)[, ]?/g)
	{
		push @vec2, $_;
	}
	return "vectors not the same size" if (scalar @vec1 != scalar @vec2);
	$variable{ans} = 0;
	for (0 .. (scalar @vec1 - 1))
	{
		$variable{ans} += $vec1[$_] * $vec2[$_];
	}
	return $variable{ans};
}

sub cross {
	$_ = shift;
	my ($ax, $ay, $az, $bx, $by, $bz) =
		m/\((-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)\)\s*\((-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)\)/g;

	my $x = $ay * $bz - $az * $by;
	my $y = $az * $bx - $ax * $bz;
	my $z = $ax * $by - $ay * $bx;

	return "($x,$y,$z)";
}

sub scriptif {
  my $text = shift;
  $text = parse_variables($text);
  $text = parse_calculations($text);

  my ($if, $then, $else) = split ':', $text;

  my ($a, $test, $b) =
    $if =~ m/^(.*)\s+(!=|[=<>]=|lt|<|gt|>|eq|ne)\s+(.*)$/;


  return "I don't understand :(" if !defined $a or !defined $test or !defined $b or !defined $then;
  my $bool =
    ($test eq '!=') ? $a != $b
  : ($test eq '==') ? $a == $b
  : ($test eq '<=') ? $a <= $b
  : ($test eq '>=') ? $a >= $b
  : ($test eq 'eq') ? $a eq $b
  : ($test eq 'ne') ? $a ne $b
  : ($test eq 'lt') ? $a lt $b
  : ($test eq '<' ) ? $a <  $b
  : ($test eq 'gt') ? $a gt $b
  : ($test eq '>' ) ? $a >  $b
  :                   undef;

  return "Soemthing broak :<" if !defined $bool;

  return parse_command($then) if($bool);
  return parse_command($else) if(!$bool and defined $else);
  return;
}

sub scriptdo {
  my $text = shift;

  my ($count, $what) = $text =~ m/^(\d+)\s+(.+)$/g;

  my @responses;

	return (wantarray) ? ["!do disabled", "MSG"] : "$what, $count times" if !$constant{V_DO_ENABLED};
	return (wantarray) ? ["too much to do!", "MSG"] : "$what, lots of times" if $count > $global_var{max_do};

  for (1 .. $count) {
    if(wantarray) {
      # Raw command, rather than %(!do)
      my @response = parse_all($what);
      push @responses, @response;
    }
    else {
      # was a %(!do)
      # Disabled nested !dos, to re-enable them comment out the next line
      return "Don't nest !do plz. :(";
      my $response = parse_all($what);
      push @responses, $response;
    }
  }

  return (wantarray) ? @responses : join ' ', @responses;
}

sub find_scripts
{
	my $search = shift;
	open SCRIPTS, "<", "$global_var{home}/$global_var{script_path}/$global_var{scripts_file}";
	my @res = (defined $search) 
		? grep { (split '\t')[0] eq $search } <SCRIPTS>
		: <SCRIPTS>;
	close(SCRIPTS);

	return @res;
}

sub lscripts {
	my @scripts = find_scripts();

	for(@scripts)
	{
		$_ =~ s/^([^\t]*)\t.*$/$1/g;
	}
	my $scriptstring = join(', ', @scripts);
	# this should not be necessary
	$scriptstring =~ s/\n//g;
	return (wantarray) ?
		(["$global_var{num_scripts} scripts:", "MSG"],
		[$scriptstring, "MSG"]) : 
		$scriptstring;
}

sub lscript {
 	my $scriptname = shift;
	return "not a script name" if !$scriptname;

	my @found = find_scripts($scriptname);

	return "more than one script with that name D:" if scalar @found > 1;
	return "no script with that name" if scalar @found < 1;
	return join(': ', split('\t', $found[0]));
}

sub rscript {
	my $args = shift;
	return "not a script name" if !length $args;

	my @args = split(' ', $args);
	local $variable{'#'} = scalar(@args);
	#local @variable{0..$#args} = @args;
	for(0..$#args)
	{
		$variable{$_} = $args[$_];
		$variable{"$_-"} = join(' ', @args[$_..$#args]);
	}

	my @found = find_scripts($args[0]);

	return "more than one script with that name D:" if scalar @found > 1;
	return "no script with that name" if scalar @found < 1;

	my ($name, $script) = split('\t', $found[0]);
	my @res;
	if(wantarray)
	{
		for(split(';', $script))
		{
			my @ans = parse_all($_);
			push @res, @ans;
		}
		return @res;
	}
	else
	{
		for(split(';', $script))
		{
			my $ans = parse_all($_);
			push @res, $ans;
		}
		return join(' ', @res);
	}
}

sub ascript {
	my $args = shift;
	return "no tabs allowed!" if $args =~ m/\t/;
	my ($name, $script) = $args =~ m/([^:]*): (.*)$/;
	return "not a script name" if !$name;
	return "no script content" if !$script;
	return "already a script with that name" if find_scripts($name);

	open(SCRIPTS, ">>$global_var{home}/$global_var{script_path}/$global_var{scripts_file}");
	print SCRIPTS "$name\t$script\n";
	close(SCRIPTS);

	$global_var{num_scripts}++;
	return "script added";
}

sub store {
	$_ = shift;
	my ($var, $val) = split " ", $_, 2;
	$user_var{$var} = $val;

	return (wantarray) ? "$val now stored in &($var)" : "$val";
}

sub vars {
	my @vals;

	VAR:
	for my $var (keys %variable) {
		my $val = $variable{$var};
		$val = "<everyone>" if $var eq 'everyone';
		$val = &$val if ref $val eq 'CODE';
		push @vals, "$var = $val";
	}
	
	VAR:
	for my $var (keys %user_var) {
		my $val = $user_var{$var};
                push @vals, "$var = $val";
	}
	return join (', ', @vals);
}

# FIXME: reinstate vurlisms &c. to replace makeshift !help

sub maths {
	my @fns;
	for my $fn (@maths_fns) {
		push @fns, $command{$fn}{usage};
	}

	return join (', ', @fns);
}

sub vurlisms {
	my @fns;
	for my $fn (@traditional_fns) {
		push @fns, $command{$fn}{usage};
	}

	return join (', ', @fns);
}

sub utilities {
	my @fns;
	for my $fn (@utility_fns) {
		push @fns, $command{$fn}{usage};
	}

	return join (', ', @fns);
}

sub scripting {
	my @fns;
	for my $fn (@script_fns) {
		push @fns, $command{$fn}{usage};
	}

	return join (', ', @fns);
}

sub commands {
	return (vurlisms(), utilities(), maths(), scripting());
}

sub wikify {
	# URL encode
	$_ = ucfirst(shift);
	s/\s/_/g;
	s/([^A-Za-z0-9_\-\.])/sprintf("%%%02X", ord($1))/seg;
	return "http://en.wikipedia.org/wiki/$_";
}

sub uncyclopedia {
	# URL encode
	$_ = shift;
	s/\s/_/g;
	s/([^A-Za-z0-9_\-\.])/sprintf("%%%02X", ord($1))/seg;
	return "http://uncyclopedia.org/wiki/$_";
}

sub google {
	# URL encode
	$_ = shift;
	s/\s/\+/g;
	s/([^A-Za-z0-9_\-\.\+])/sprintf("%%%02X", ord($1))/seg;
	return "http://www.google.co.uk/search?q=$_";
}

sub srd {
	# URL encode
	$_ = shift;
	s/\s/_/g;
	s/([^A-Za-z0-9_\-\.])/sprintf("%%%02X", ord($1))/seg;
	return "http://d20srd.org/srd/$_";
}

sub define {
	# URL encode
	$_ = shift;
	s/\s/_/g;
	s/([^A-Za-z0-9_\-\.])/sprintf("%%%02X", ord($1))/seg;
	return "http://dictionary.reference.com/browse/$_";
}

sub evaluate {
	return ":\\/" if $session_var{nick} =~ m/totes/;
	return "$session_var{nick}, no :(" if(!$constant{V_EVAL_ENABLED});
	my $safe = new Safe;
	# Irssi ensures that our package at this point is not main.
	$safe->share_from( __PACKAGE__ , ['&server', '&nick', '&channel', '&set_constant'], 'Irssi::Irc::Server', [ qw(command) ] );

	my $cmd = shift;
	my $ret;
	return "what?" if length($cmd) == 0;

	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Useqq = 1;

	$ret = $safe->reval($cmd);
	my $out = Dumper($ret);

	return "Error -- $@" if $@;

	return "$out";
}

sub add_adverb {
	my $new_adverb = shift;

	open ADVERBS, "+<", "$global_var{home}/$global_var{script_path}/$global_var{adverbs_file}";
	my @adverbs = <ADVERBS>;
	chomp @adverbs;

	$global_var{num_adverbs} = scalar @adverbs;

	return "Adverb what?" unless $new_adverb;

	if(grep { $_ eq $new_adverb } @adverbs) {
		close ADVERBS;
		return "$new_adverb already listed, go away";
	}
	elsif (is_on_chan($new_adverb) || $new_adverb =~ m/&\(random_nick\)/) {
		close ADVERBS;
		return "no random highlights please";
	}
	else {
		print ADVERBS $new_adverb, "\n";
		close ADVERBS;
		$global_var{num_adverbs} ++;
		return "Adverb added.";
	}
}

sub add_verb {
	my $new_verb = shift;

	open VERBS, "+<", "$global_var{home}/$global_var{script_path}/$global_var{verbs_file}";
	my @verbs = <VERBS>;
	chomp @verbs;

	$global_var{num_verbs} = scalar @verbs;
	
	return "Which verb?" unless $new_verb;

	if(grep { $_ eq $new_verb } @verbs) {
		close VERBS;
		return "$new_verb already listed, go away.";
	}
	elsif (is_on_chan($new_verb) || $new_verb =~ m/&\(random_nick\)/) {
		close VERBS;
		return "no random highlights please";
	}
	else {
		print VERBS $new_verb, "\n";
		close VERBS;
		$global_var{num_verbs}++;
		return "Verb added.";
	}
}


#sub cookies_and_cream {
#	my $rand = rand(200);
#	
	# ...
#	
#	return ($rand < 0.2) ? ["", "ACTION"]
#		: ["gives everyone a monkfish", "ACTION"]
#		if($rand < 1);
#}

sub parse_variables {
	my $text = shift;

	# first, parse out the actual variables
	$text = do_var_parse($text);

	# Then parse out the double variables into single variables
	$text =~ s/&&\((.*)\)/&\(\1\)/g;
	return $text;
}

sub do_var_parse {
	my $text = shift;

	use Text::Balanced qw( extract_bracketed );

	# This will go backwards because the .* in the prefix is greedy.
	# Thus, $remainder will never contain a variable.
	my($match, $remainder, $prefix) = extract_bracketed ($text, "()", "(?:^|.*)(?:^|[^&])&");
 
	#recursion unfolds when there's no match!
	return $text if ($match eq q());

	# $match comes with parentheses thrown in free
	$match =~ s/^\(//;
	$match =~ s/\)$//;

	# do it all again for the matched set to get nested variables
	my $parsed_var_name = do_var_parse($match);

	my $val =   $variable{$parsed_var_name} || 
	          $global_var{$parsed_var_name} ||
	            $user_var{$parsed_var_name} ||
	         $session_var{$parsed_var_name};

	# two methods of handling nonexistant vars, neither really worked
	# so a nonexistent value is an empty value
	#$val = "&&($parsed_var_name)" if !defined $val;
	#return $text if !defined $val;
	$val = &$val if (ref $val eq 'CODE');

	# escape with && if the value is also a variable name, and the same with %
	$val =~ s/(&\(.+\))/&\1/g;
	$val =~ s/(%\(.+\))/%\3/g;

	# $prefix contains the & at the end.
	$prefix =~ s/&$//;

	# Do it again with the new string. If we just use the prefix we don't
	# parse the outer variables, you see.
	$text = do_var_parse($prefix.$val.$remainder);
	return $text;
}

sub parse_calculations {
	# Exactly the same as parse_variables except we use %
	my $text = shift;
	
	$text = do_calc_parse($text);
	
	$text =~ s/%%/%/g;

	return $text;
}

sub do_calc_parse {
	my $text = shift;

	use Text::Balanced 
qw( extract_bracketed );

	my($match, $remainder, $prefix) = extract_bracketed ($text, "()", "(?:^|.*)(?:^|[^%])%");

	# Recursion unfolds here
	return $text if($match eq q());

	# remember to remove the parentheses from $match
	$match =~ s/^\(//;
	$match =~ s/\)$//;

	# nested commands can form the arguments to the command or even
	# the name of it.
	my $parsed_command = do_calc_parse($match);

	# Then do it. 
	my $answer = parse_command($match);

	return $text if !defined $answer;
	# if the command returns a string with a command in it, parse it out.
	# Do the same to variables.
	$answer =~ s/%/%%/g;
	$answer =~ s/&/&&/g;

	# The prefix had the % on it.
	$prefix =~ s/%$//g;

	# Now we have a new string. Do it again to that.
	$text = do_calc_parse($prefix.$answer.$remainder);
	return $text;
}

sub parse_command {
	my $text = shift;
	
	$text =~ s/^\s+//g;
	$text =~ s/^\!([^vV].*|)url [Vv](.*)/!vurl $1$2/g;
	# all this [^vV] stuff is to ensure she doesn't spooner normal vurls (which messes with letter case)

	if (my ($comm,$args) = $text =~ m/^!([^\s]+)(.*)$/g) {
		$args =~ s/^\s+//g;
		$args =~ s/\s+$//g;

		$comm = lc($comm);

		if (!exists $command{$comm}) {
				# Is this an alternative command? Vurl's nick as !vurl takes priority
				return $command{'vurl'}{'sub'}($args)
						if $comm eq lc($session_var{server}{nick});
				# if it matches twice, hell with it. I don't care
				my $alt = first { $comm =~ /$_/i } keys %alternative;
				$comm = $alternative{$alt} if defined $alt;
		}
		return if !exists $command{$comm};
		return $command{$comm}{'sub'}($args);
	}
	
	return;
}

sub parse_all {
	my $text = shift;

	$text = parse_variables($text);

	$text = parse_calculations($text);

	# This sends the current wantarray value into the parse_command,
	# so if we've called parse_all from within some recursion we keep
	# asking for scalars. The only time this will return an array is to
	# the message handler.
	return parse_command($text);
}

sub nicklist # Generate a list of the nicks in a channel, and return it as an array. (Doesn't return one's own nick)
{
	my $server = shift || $session_var{server};
	my $target = shift || $session_var{target};

	my $channel = $server->channel_find($target) || return; 	# Need to get the channel object "hash version"
	my @nicks_hash = $channel->nicks(); 		# Stores the "hash-versions" of the nicks
	my @nicks; 					# Stores the plain text nicks
	for(@nicks_hash)
	{
		push @nicks, $_->{nick};	# Store the actual plain text nickname in @nicks
	}
	
	return @nicks;
}

sub invite
{
	my ($server, $channel, $nick) = @_;
	
	if($constant{V_AUTOINVITE_ENABLED})
	{
		$server->command("JOIN $channel");
		$server->command("MSG $channel hai2u, $nick");
	}
}


sub mode
{
	my ($server, $mode, $nick) = @_;
	my ($channel, $modechange, $targetuser) = split(/ /,$mode,3);

	return; # due to autovoice, let's not, eh?

	#if($modechange =~ m/\+b/) ## This might not work for "compound mode-changes"
	if($modechange =~ m/\+\w*b/) #mwahax test~ perlreref
	{
		$server->command("MSG $channel lol, b&");
	}
	
	if($modechange =~ m/\+\w*v/) # Sometimes, say 'lol vois'
	{
		if(int(rand()*10) == 0) { $server->command("MSG $channel lol vois"); }
	}
}

sub init {
	my ($data, $server, $witem) = @_;
	
	if($server == 0)
	{
		print "Can't initialise yet; not connected to server";
		return;
	}

	auth();
}

sub auth {
	my $server = $session_var{server};
	open(AUTH_HANDLE, "<", "$global_var{home}/.irssi/scripts/auth.txt");
	my $auth = <AUTH_HANDLE>;
	chomp $auth;
	close AUTH_HANDLE;
	my $nick = $server->{nick};

	# Auth and set +x
	$server->command("MSG q\@cserve.quakenet.org auth vurl $auth");
	$server->command("MODE $nick +x");
}

sub join_chan {
}

sub action
{
	my ($server, $text, $nick, $host, $channel) = @_;
#	Irssi::print("@_");
#	Irssi::print("Server: $server, data: $text, nick: $nick, channel: $channel");
##	$server->command("MSG $channel $nick, you said $text on $channel, on $server"); ## this DOES work
	
 	#my $hackstring = "$server $channel :$text $nick";
	#&commands($hackstring); ## horrible way of doing it! :p (fittingly, it doesn't work)
	message($server, "$channel :/me $text", $nick); # this?
}

sub ctcp ## I don't think this really does anything useful
{
	my ($server, $data, $nick) = @_;
	my ($target, $text) = split(/ :/, $data, 2);
	
	if($text eq "") {$text = " "}
	$server->command("MSG $target $text");
}

sub message {
	# Get the relevant data and split it into useful pieces
	my ($server, $data, $nick, $host) = @_;
	my ($target, $text) = split(/ :/, $data, 2);
	my $uc = (uc $text eq $text) && (() = $text =~ /([[:upper:]])/g) >= 3;
	my $func = sub { drunken($uc ? uc shift : shift) };

	$session_var{message_count}++;

	$session_var{server} = $server;
	$session_var{nick  } = $nick;
	$session_var{target} = $target;
	$session_var{text  } = $text;
	$session_var{host  } = $host;

	# for private messages
	$session_var{'target'} = $nick if($target eq $server->{nick});
	
	my @res;
	# benmachine: vurl should respond to rum et al first, and then execute the command
	# NOTE: reread documentation because I've fiddled with stuff
	my @ar = grep { $text =~ $_ } keys %autoresponse;
	if(scalar @ar) {
		@res = &{$autoresponse{$ar[0]}};
	}

	# screw with Becquerel's rand-twiddling
	rand for($session_var{message_count} % 20);

	# See? Here we wantarray. Everywhere else we don't.
	push @res, parse_all($text);

	# Nothing to say? Blurt out random crap!
#	if (!scalar @res) {
#		for (@random_responses) {
#			@res = $_->($text);
#		}
#	}

	# If this command is boring but people are bandwagoning, jump on
	my $ref = $global_var{parroting}->{$session_var{target}};
	my $count = 0;
	if(!@res && $constant{V_PARROT_ENABLED} && defined $ref)
	{
		my ($oldtext, $oldnick, $oldcount) = @$ref;
		$count = ($text eq $oldtext) ? $oldcount + ($nick ne $oldnick ? 1 : 0) : 0;
		if($count == 1)
		{
			my $how = "MSG";
			$count += 1;
			@res = ($text);
		}
	}
	$global_var{parroting}->{$session_var{target}} = [$text, $nick, $count];
	# Still nothing to say? Shame on you, vurl!
	for my $args (@res) { 
		next if !length $args; # why is it iterating over an empty array?
		my ($what_to_say, $how_to_say_it);
		if (ref $args ne 'ARRAY')
		{
			my %cmds = ( me => 'ACTION' );
			$what_to_say = $func->($args);
			if ($what_to_say =~ m/^!/) { # some people just can't be trusted with a robot
				return;
            }
			if ($what_to_say =~ m!^/(\w+)! and exists $cmds{$1})
			{
				$how_to_say_it = $cmds{$1};
				$what_to_say =~ s!^/\w+\s+!!;
			}
			else
			{
				$how_to_say_it = 'MSG';
			}
		}
		else
		{
			($what_to_say, $how_to_say_it) = @$args;
			$what_to_say = $func->($what_to_say);
		}
		$server->command( qq($how_to_say_it $session_var{target} $what_to_say) ); 
	} 
	
	# Wait 5 non-warks before it's OK to wark again
	$global_var{wark_again}->{$session_var{target}}++
		unless ($text =~ m#:\\/#);
}


Irssi::command_bind init => \&init;
# Irssi::command_bind dv => \&direct_eval; ## This command is for use directly into the vurl window.

# But don't wait for the user to /init, just call it as soon as the script loads:
# Alas, this doesn't work.
#&init;

## Irssi::signal_add_first("ctcp msg", "testing");
# benmachine: signal_add_last lets irssi process the signal first, which preserves message order in the screen
Irssi::signal_add_last("event privmsg", "message");
Irssi::signal_add_last("message invite", "invite");
Irssi::signal_add_last("message irc action", "action");
Irssi::signal_add_last("event mode", "mode"); # Would be nice to do this to respond to changes in mode
# Irssi::signal_add('default ctcp msg', 'ctcp');

# eval commands - these ones are available to eval's Safe container

sub server {
	return $session_var{server};
}

sub channel {
	return $session_var{target};
}

sub nick {
	return $session_var{nick};
}

sub set_constant {
	die ("no :(") unless trusted_user();

	my ($key, $value) = @_;
	$constant{$key} = $value;
}

sub warfighter {
	my @warfighters = (
	                    "Cadenza",
	                    "Cherri",
	                    "Demitras",
	                    "Heketch",
	                    "Hepzibah",
	                    "Hikaru",
	                    "Kallistar",
	                    "Kehrolyn",
	                    "Khadath",
	                    "Lixis",
	                    "Luc",
	                    "Magdelina",
	                    "Rukyuk",
	                    "Sagas",
	                    "Seth",
	                    "Tatsumi",
	                    "Vanaah",
	                    "Zaamassal"
	                  );
	
	return $warfighters[rand @warfighters];
}

sub devastationfighter {
	my @devastationfighters = (
	                            "Adjenna",
	                            "Alexian",
	                            "Arec",
	                            "Aria",
	                            "Byron",
	                            "Cesar",
	                            "Clinhyde",
	                            "Clive",
	                            "Eligor",
	                            "Endrbyt",
	                            "Gaspar",
	                            "Gerard",
	                            "Iaxus",
	                            "Joal",
	                            "Kaitlyn",
	                            "Kajia",
	                            "Karin and Jager",
	                            "Lesandra",
	                            "Lymn",
	                            "Malandrax",
	                            "Marmelee",
	                            "Mikhail",
	                            "Oriana",
	                            "Ottavia",
	                            "Pendros",
	                            "Rexan",
	                            "Runika",
	                            "Shekhtur",
	                            "Tanis",
	                            "Voco"
	                          );
	
	return $devastationfighters[rand @devastationfighters];
}

sub battlecon {
	my @battleconfighters = (
	                          "Adjenna",
	                          "Alexian",
	                          "Arec",
	                          "Aria",
	                          "Byron",
	                          "Cadenza",
	                          "Cesar",
	                          "Clinhyde",
	                          "Clive",
	                          "Cherri",
	                          "Demitras",
	                          "Eligor",
	                          "Endrbyt",
	                          "Gaspar",
	                          "Gerard",
	                          "Heketch",
	                          "Hepzibah",
	                          "Hikaru",
	                          "Iaxus",
	                          "Joal",
	                          "Kaitlyn",
	                          "Kajia",
	                          "Kallistar",
	                          "Karin and Jager",
	                          "Kehrolyn",
	                          "Khadath",
	                          "Lesandra",
	                          "Lixis",
	                          "Luc",
	                          "Lymn",
	                          "Magdelina",
	                          "Malandrax",
	                          "Marmelee",
	                          "Mikhail",
	                          "Oriana",
	                          "Ottavia",
	                          "Pendros",
	                          "Rexan",
	                          "Rukyuk",
	                          "Runika",
	                          "Sagas",
	                          "Seth",
	                          "Shekhtur",
	                          "Tanis",
	                          "Tatsumi",
	                          "Vanaah",
	                          "Voco",
	                          "Zaamassal"
	                        );
	
	return $battleconfighters[rand @battleconfighters];
}

sub bastion {
	my @weapons = (
	                "Bellows",
	                "Bow",
			"Cannon",
			"Carbine",
			"Hammer",
			"Machete",
			"Mortar",
			"Musket",
			"Pike",
			"Pistols",
			"Repeater",
		      );
	
	my $firstindex = int(rand @weapons);
	my $secondindex = int(rand @weapons - 1);
	
	if ($secondindex >= $firstindex)
	{
		$secondindex++;
	}
	
	return $weapons[$firstindex] . "/" . $weapons[$secondindex];
}

sub ftl {
	my @ftlships = (
	                 "Kestrel",
	                 "Red-Tail",
	                 "Nesasio",
	                 "DA-SR 12",
	                 "Torus",
	                 "Vortex",
	                 "Osprey",
	                 "Nisos",
	                 "Man of War",
	                 "Stormwalker",
	                 "Gila Monster",
	                 "Basilisk",
	                 "Bulwark",
	                 "Shivan",
	                 "Adjudicator",
	                 "Noether",
	                 "Bravais",
	                 "Carnelian"
	               );
	
	my $shipChosen = rand @ftlships;
	if ($ftlships[$shipChosen] eq "Osprey" && (rand 5) == 0)
	{
		return "Space Penis";
	}
	
	return $ftlships[$shipChosen];
}

sub tasen {
	my @tasenshouts = (
	                    "Hold it!",
	                    "Stop!",
	                    "Hey!",
	                    "Halt!",
	                    "Contact!",
	                    "Incoming!",
	                    "Intruder!",
	                    "Hostile!"
	                  );
	
	return $tasenshouts[rand @tasenshouts];
}

sub komato {
	my @komatoshouts = (
	                     "Get her!",
	                     "Die!",
	                     "C'mere!",
	                     "Kill!",
	                     "Annihilate!",
	                     "Terminate!"
	                   );
	
	return $komatoshouts[rand @komatoshouts];
}

sub kalir {
	my @kalirphrases = (
	                     "ALIVE.",
	                     "DEAD.",
	                     "LEG.",
	                     "MAXIMUM KILLDUDES.",
	                     "CRAB."
	                   );
	
	return $kalirphrases[rand @kalirphrases];
}

sub hanftl {
	my @hanftl = (
	               "OH GOD NO",
	               "HOW CAN EVERYTHING BE ON FIRE AT ONCE?",
	               "WHY DOES THIS AUTO-SCOUT HAVE TWO ION BOMBS?",
	               "D:",
	               ":D",
	               "Glaive Beam and Pre-Igniter! :D",
	               "*SIX* MANTIS BOARDERS?",
	               "How do you like ARTILLERY BEAM, Flagship?",
	               "I've got four mantis and four engi.  Life is good.",
	               "What.",
	               "WHAT",
	               "AS;DLKFJA;LDKJ",
	               "Breach missle got past my defense drone and hit my drone control. :(",
	               "RIP Star Sapphire. :(",
	               "This game hates me",
	               "First ship I meet has two Burst Laser IIs.  WHY?",
	               "FFFFFFFFFFFFFFFFFF",
	               "AUGH",
	               "Three sun beacons IN A ROW?",
	               "What possessed me to play as the DA-SR 12 again?",
	               "Piloting, shields, and drone control are all down. :<",
	               "DEAD.",
	               "im so dead",
	               "help",
	               "Oh god, which wire do I cut?",
	               "NOOOOOOOO",
	               "MANTIS BOARDERS *AND* A BOARDING DRONE?",
	               "wait what",
	               "WHY DOES A SECTOR 1 SHIP HAVE A GLAIVE BEAM",
	               "Ioned shields in an asteroid field D:",
	               "Where are hull repairs when you need them?",
	               "OF COURSE the breach missile hits piloting.  OF COURSE.",
	               "BREACH BOMB TO MY MEDBAY?  BUT I JUST MOVED MY ZOLTAN IN THERE TO HEAL!",
	               "Oh great, my door control is on fire.",
	               "Shield hacking ship with a beam drone?  REALLY?",
	               "OH GOD THEY ACTUALLY HIT WITH A FIRE BEAM",
	               "Why does the Flagship have a Defense II drone?",
	               "Christ, just hit four 'NOPE NOTHING' beacons in a row"
	             );
	
	return $hanftl[rand @hanftl];
}

sub sober_up {
	$session_var{drunk} = 0;
	return "/me shudders as her system is flooded with anti-alcohol";
}

sub pair {
	#attack pair
	my $arg = shift;
	#player who submitted it
	my $nick = $session_var{nick};
	#server we're on
	my $server = $session_var{server};
	#channel we're on
	my $channel = $session_var{arena_channel};
	
	if(!(defined $session_var{first_player}))
	{
		$session_var{first_player} = $nick;
		$session_var{first_move} = $arg;
		my $returnstring = "Move recieved from " . $nick . ".";
		$server->command("MSG $channel $returnstring");
		return "'kay"
	}
	if($session_var{first_player} eq $nick)
	{
		$session_var{first_move} = $arg;
		my $returnstring = "New move from " . $nick . ".";
		$server->command("MSG $channel $returnstring");
		return "'kay"
	}
	if(!(defined $session_var{second_player}))
	{
		$session_var{second_player} = $nick;
		$session_var{second_move} = $arg;
		my $returnstring = "Moves recieved from " . $session_var{first_player} . " and " . $nick . ".";
		$server->command("MSG $channel $returnstring");
		return "'kay"
	}
	if($session_var{second_player} eq $nick)
	{
		$session_var{second_move} = $arg;
		my $returnstring = "New move from " . $nick . ".";
		$server->command("MSG $channel $returnstring");
		return "'kay"
	}
	
	return "Ow, my head!  Only two players plz. :<";
}

sub reveal {
	if(!(defined $session_var{first_player}))
	{
		return "But no cards are face-down!";
	}
	if(!(defined $session_var{second_player}))
	{
		$session_var{first_player} = undef;
		$session_var{first_move} = undef;
		return "Discarding the one attack pair played.";
	}
	my $returnstring = "<" . $session_var{first_player} . "> " . $session_var{first_move} . " vs. ";
	$returnstring = $returnstring . "<" . $session_var{second_player} . "> " . $session_var{second_move};
	
	$session_var{first_player} = undef;
	$session_var{first_move} = undef;
	$session_var{second_player} = undef;
	$session_var{second_move} = undef;
	
	return $returnstring;
}

sub settrap {
	$session_var{trap} = shift;
	my $server = $session_var{server};
	my $channel = $session_var{arena_channel};
	$server->command("MSG $channel Trap set.");
	return "'kay";
}

sub showtrap {
	if(!(defined $session_var{trap}))
	{
		return "No trap was set!";
	}
	my $returnstring = $session_var{trap};
	$session_var{trap} = undef;
	return $returnstring;
}

sub cleartrap {
	$session_var{trap} = undef;
	return "Trap cleared.";
}

sub setarena {
	#set the BattleCON arena channel.
	my $channel = $session_var{target};
	$session_var{arena_channel} = $channel;
	return "BattleCON arena channel set to $channel.";
}

sub setenviro {
    my $input = shift;
    my @inputlist = split(' ', $input, 2);
    if(@inputlist[1] eq '')
    {
        return "Usage: !setenviro [position] [token]";
    }
    push(@{$session_var{env_coords}}, $inputlist[0]);
    push(@{$session_var{env_tokens}}, $inputlist[1]);
    
    return "Environment marker set.";
}

sub environment {
    my $returnstring = "";
    for (my $i = 0; $i < @{$session_var{env_coords}}; $i++)
    {
        $returnstring = $returnstring . "Position " . $session_var{env_coords}[$i] . ": " . $session_var{env_tokens}[$i] . ".  ";
    }
    
    if($returnstring eq '')
    {
        return "No environment set!";
    }
    $session_var{env_coords} = [];
    $session_var{env_tokens} = [];
    return $returnstring;
}
