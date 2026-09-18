#!/bin/bash
#
# Renders a Markdown file to a PDF that looks like the file does on github.com.
#
# The Markdown is rendered by GitHub itself (https://api.github.com/markdown),
# so tables, syntax highlighting, emojis and footnotes come out exactly like
# they do in the browser. What that API does not do for a file in a repository
# is done here: alerts (> [!TIP]), task list checkboxes and anchor ids that
# work without JavaScript. The result is styled with github-markdown.css, all
# images are embedded, and headless Chrome prints the page.
#
# The five Octicons in resources/pdf/ were taken from the API itself, which
# does render alerts in mode "gfm". To refresh one of them:
#
#   printf '> [!TIP]\n> x\n' |
#     perl -0777 -pe 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; $_ = qq({"text":"$_","mode":"gfm"})' |
#     curl -sS -X POST -H "Content-Type: application/json" --data-binary @- \
#          https://api.github.com/markdown |
#     perl -0777 -ne 'print $1 if m{(<svg\b.*?</svg>)}s' > resources/pdf/alert_tip.svg
#
# Copyright (c) 2026 Johann N. Löfflmann, <https://johann.loefflmann.net>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="${SCRIPT_DIR}/../config"
RES_DIR="${SCRIPT_DIR}/../resources/pdf"
REPO_DIR="${SCRIPT_DIR}/.."

source "${SCRIPT_DIR}/lib/common.include"
source "${CFG_DIR}/make_pdf.cfg"


#---------------------------------------------------------------
function usage {
#---------------------------------------------------------------
cat << EOL
Usage: $(basename "$0") [options] [<markdown-file>]

Renders a Markdown file to a PDF that looks like the file does on github.com.

  <markdown-file>    the file to render. Defaults to ${MD_FILE_DEFAULT} in the
                     repository, which is rendered to ${PDF_FILE_DEFAULT}.
                     For any other file the PDF is written next to it, unless
                     -o says otherwise.
  -o, --output <pdf> where to write the PDF
  -t, --title <text> the PDF title. Defaults to the first heading of the file.
  --no-embed         do not embed the images as data: URIs, let Chrome load
                     them from the network while it prints
  --keep-html        keep the intermediate HTML next to the PDF
  --ci               add --no-sandbox to the Chrome call, needed in containers
                     (implied when \$CI is set or when running as root)
  -h, --help         print this help and exit

Environment:
  GITHUB_TOKEN       raises the rate limit of the Markdown API from 60 to 5000
                     requests per hour
  CHROME             the Chrome or Chromium binary to print with
EOL
}


#---------------------------------------------------------------
function fail {
#---------------------------------------------------------------
  printf >&2 "FATAL: %s Exit.\n" "$1"
  exit 1
}


#---------------------------------------------------------------
function warn {
#---------------------------------------------------------------
  printf >&2 "WARNING: %s\n" "$1"
}


# writes the Perl helpers that do the text processing to the work directory
#---------------------------------------------------------------
function writeHelpers {
#---------------------------------------------------------------

cat > "${WORK_DIR}/json_body.pl" << 'EOL'
# params: the API mode. Reads Markdown from stdin, writes the API request body.
use strict;
use warnings;
my $mode = shift @ARGV;
local $/;
binmode STDIN;
binmode STDOUT;
my $text = <STDIN>;
$text = q{} unless defined $text;
$text =~ s/\\/\\\\/g;
$text =~ s/"/\\"/g;
$text =~ s/\r/\\r/g;
$text =~ s/\n/\\n/g;
$text =~ s/\t/\\t/g;
$text =~ s/([\x00-\x1f])/sprintf(q{\\u%04x}, ord $1)/ge;
print qq({"text":"$text","mode":"$mode"});
EOL

cat > "${WORK_DIR}/postprocess.pl" << 'EOL'
# params: the directory with the alert icons. Reads the HTML of the API from
# stdin and adds what mode=markdown does not render for a file: alerts, task
# list checkboxes, and ids that internal links can reach without JavaScript.
use strict;
use warnings;
my $svgdir = shift @ARGV;
my %label = (note => q{Note}, tip => q{Tip}, important => q{Important},
             warning => q{Warning}, caution => q{Caution});
my %icon;
for my $type (keys %label) {
    $icon{$type} = q{};
    if (open my $fh, q{<}, "$svgdir/alert_$type.svg") {
        local $/;
        my $svg = <$fh>;
        close $fh;
        $svg =~ s/\s+\z//;
        $icon{$type} = $svg;
    }
}

binmode STDIN;
binmode STDOUT;
my @lines = <STDIN>;
my @out;
my @stack;

for (my $i = 0; $i <= $#lines; $i++) {
    my $line = $lines[$i];

    if ($line =~ m{^<blockquote>\s*$}) {
        my $next = defined $lines[$i + 1] ? $lines[$i + 1] : q{};
        # GitHub renders a blockquote as an alert only if the marker is alone
        # on the first line of the blockquote
        if ($next =~ m{^<p>\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\](</p>)?\s*$}) {
            my $type = lc $1;
            my $marker_closes_paragraph = defined $2;
            push @stack, q{alert};
            push @out, qq{<div class="markdown-alert markdown-alert-$type">\n};
            push @out, qq{<p class="markdown-alert-title">$icon{$type}$label{$type}</p>\n};
            # the marker line was the opening <p> of the first paragraph, so
            # that paragraph needs a new opening tag
            push @out, qq{<p>\n} unless $marker_closes_paragraph;
            $i++;
            next;
        }
        push @stack, q{quote};
        push @out, $line;
        next;
    }

    if ($line =~ m{^</blockquote>\s*$}) {
        my $kind = pop @stack;
        $kind = q{quote} unless defined $kind;
        push @out, $kind eq q{alert} ? qq{</div>\n} : $line;
        next;
    }

    push @out, $line;
}

my $html = join q{}, @out;

# github.com prefixes anchor ids with user-content- and maps the links to them
# with JavaScript, which a PDF cannot do
$html =~ s/\bid="user-content-/id="/g;

# mode=markdown leaves the brackets of a task list as they are
$html =~ s{<li>\[ \](\s)}
          {<li class="task-list-item"><input type="checkbox" disabled="" class="task-list-item-checkbox">$1}g;
$html =~ s{<li>\[[xX]\](\s)}
          {<li class="task-list-item"><input type="checkbox" checked="" disabled="" class="task-list-item-checkbox">$1}g;

print $html;
EOL

cat > "${WORK_DIR}/images.pl" << 'EOL'
# params: "list" or "embed" plus the file that maps a src to a data: URI.
# Reads HTML from stdin.
use strict;
use warnings;
my ($action, $mapfile) = @ARGV;
binmode STDIN;
binmode STDOUT;
# a scope of its own, the map below is read line by line
my $html = do { local $/; <STDIN> };

if ($action eq q{list}) {
    my %seen;
    while ($html =~ m{<img\b[^>]*?\bsrc="([^"]*)"}gs) {
        my $src = $1;
        next if $src =~ m{^data:} || $src eq q{};
        next if $seen{$src}++;
        print "$src\n";
    }
    exit 0;
}

open my $fh, q{<}, $mapfile or die "cannot read $mapfile\n";
my %map;
local $/ = "\n";
while (my $entry = <$fh>) {
    chomp $entry;
    my ($src, $uri) = split /\t/, $entry, 2;
    $map{$src} = $uri if defined $uri && length $uri;
}
close $fh;
for my $src (keys %map) {
    my $quoted = quotemeta $src;
    my $uri = $map{$src};
    $html =~ s/src="$quoted"/src="$uri"/g;
}
print $html;
EOL

cat > "${WORK_DIR}/assemble.pl" << 'EOL'
# params: template, CSS file, body file. Writes the complete HTML page.
# The title comes from PDF_TITLE, the lang attribute from PDF_LANG.
use strict;
use warnings;
sub slurp {
    my $file = shift;
    open my $fh, q{<}, $file or die "cannot read $file\n";
    binmode $fh;
    local $/;
    my $content = <$fh>;
    close $fh;
    return defined $content ? $content : q{};
}
my ($template, $cssfile, $bodyfile) = @ARGV;
my $page = slurp($template);
my $title = defined $ENV{PDF_TITLE} ? $ENV{PDF_TITLE} : q{};
my $lang = defined $ENV{PDF_LANG} && length $ENV{PDF_LANG} ? $ENV{PDF_LANG} : q{en};
for my $attribute ($title, $lang) {
    $attribute =~ s/&/&amp;/g;
    $attribute =~ s/</&lt;/g;
    $attribute =~ s/>/&gt;/g;
    $attribute =~ s/"/&quot;/g;
}
# the title first, the body could contain the placeholder as text
$page =~ s/__TITLE__/$title/;
$page =~ s/__LANG__/$lang/;
$page =~ s/__CSS__/slurp($cssfile)/e;
$page =~ s/__BODY__/slurp($bodyfile)/e;
binmode STDOUT;
print $page;
EOL

cat > "${WORK_DIR}/title.pl" << 'EOL'
# Reads HTML from stdin, prints the text of its first h1.
use strict;
use warnings;
binmode STDIN;
binmode STDOUT;
local $/;
my $html = <STDIN>;
exit 0 unless defined $html && $html =~ m{<h1[^>]*>(.*?)</h1>}s;
my $title = $1;
$title =~ s/<[^>]*>//g;
$title =~ s/&lt;/</g;
$title =~ s/&gt;/>/g;
$title =~ s/&quot;/"/g;
$title =~ s/&#39;/'/g;
$title =~ s/&amp;/&/g;
$title =~ s/\s+/ /g;
$title =~ s/^ //;
$title =~ s/ $//;
print $title;
EOL
}


# finds a Chrome or Chromium to print with, sets CHROME
#---------------------------------------------------------------
function findChrome {
#---------------------------------------------------------------
  local candidate
  if [ -n "$CHROME" ]; then
    if [ -x "$CHROME" ] || type -P "$CHROME" > /dev/null; then
      return
    fi
    fail "$(printf "CHROME is set to \"%s\", but that is not an executable." "$CHROME")"
  fi
  for candidate in "${CHROME_CANDIDATES[@]}"; do
    if [ -x "$candidate" ] || type -P "$candidate" > /dev/null; then
      CHROME="$candidate"
      return
    fi
  done
  fail "no Chrome or Chromium found. Install one, or point CHROME to its binary."
}


# params: Markdown file, target HTML file
# lets GitHub render the Markdown
#---------------------------------------------------------------
function renderMarkdown {
#---------------------------------------------------------------
  local md="$1" html="$2"
  local body="${WORK_DIR}/body.json"
  local -a auth=()
  local status

  perl "${WORK_DIR}/json_body.pl" "$API_MODE" < "$md" > "$body" ||
    fail "$(printf "could not build the request body from %s." "$md")"

  [ -n "$GITHUB_TOKEN" ] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

  printf "Rendering %s with %s (mode %s) ...\n" "$(basename "$md")" "$API_URL" "$API_MODE"
  status="$(curl -sS --retry 3 --retry-delay 2 -o "$html" -w '%{http_code}' \
                 -X POST \
                 -H "Accept: application/vnd.github+json" \
                 -H "X-GitHub-Api-Version: 2022-11-28" \
                 -H "Content-Type: application/json" \
                 "${auth[@]}" \
                 --data-binary "@${body}" \
                 "$API_URL")" ||
    fail "$(printf "could not reach %s. Is there a network connection?" "$API_URL")"

  case "$status" in
    200) ;;
    401) fail "the Markdown API rejected GITHUB_TOKEN (HTTP 401)." ;;
    403|429) fail "$(printf "the Markdown API refused the request (HTTP %s). Without GITHUB_TOKEN it allows 60 requests per hour, with a token 5000." "$status")" ;;
    *) fail "$(printf "the Markdown API returned HTTP %s: %s" "$status" "$(head -c 200 "$html")")" ;;
  esac
  [ -s "$html" ] || fail "the Markdown API returned an empty document."
}


# params: source directory for relative image paths, HTML file to work on
# downloads every image and replaces its URL with a data: URI
#---------------------------------------------------------------
function embedImages {
#---------------------------------------------------------------
  local base_dir="$1" html="$2"
  local map="${WORK_DIR}/images.map"
  local list="${WORK_DIR}/images.list"
  local file="${WORK_DIR}/image.bin"
  local count=0 embedded=0
  local src type encoded

  perl "${WORK_DIR}/images.pl" list < "$html" > "$list"
  : > "$map"

  while IFS= read -r src; do
    [ -n "$src" ] || continue
    count=$((count + 1))
    type=""
    # a leftover of the previous round must not end up in the document
    rm -f "$file"
    case "$src" in
      http://*|https://*)
        type="$(curl -fsSL --retry 2 --max-time 60 -o "$file" -w '%{content_type}' "$src")" || type=""
        ;;
      *)
        # a path relative to the Markdown file
        if [ -f "${base_dir}/${src}" ]; then
          cp "${base_dir}/${src}" "$file" && type="$(mimeTypeOf "$src")"
        elif [ -f "$src" ]; then
          cp "$src" "$file" && type="$(mimeTypeOf "$src")"
        fi
        ;;
    esac

    if [ -z "$type" ] || [ ! -s "$file" ]; then
      warn "$(printf "could not embed %s, Chrome has to load it while printing." "$src")"
      continue
    fi
    # content_type can be "image/svg+xml;charset=utf-8"
    type="${type%%;*}"
    case "$type" in
      image/*) ;;
      *) warn "$(printf "%s is a %s rather than an image, it is not embedded." "$src" "$type")"; continue ;;
    esac

    encoded="$(openssl base64 -A -in "$file")" || encoded=""
    if [ -z "$encoded" ]; then
      warn "$(printf "could not encode %s." "$src")"
      continue
    fi
    printf '%s\t%s\n' "$src" "data:${type};base64,${encoded}" >> "$map"
    embedded=$((embedded + 1))
  done < "$list"

  if [ "$count" -gt 0 ]; then
    perl "${WORK_DIR}/images.pl" embed "$map" < "$html" > "${html}.embedded" &&
      mv "${html}.embedded" "$html" ||
      fail "could not embed the images."
    printf "Embedded %s of %s images.\n" "$embedded" "$count"
    local remaining
    remaining="$(perl "${WORK_DIR}/images.pl" list < "$html" | wc -l | tr -d ' ')"
    [ "$remaining" = "0" ] ||
      warn "$(printf "%s image(s) could not be embedded, Chrome has to load them while it prints." "$remaining")"
  fi
}


# params: a file name
# prints the media type that belongs to its extension
#---------------------------------------------------------------
function mimeTypeOf {
#---------------------------------------------------------------
  case "$(printf '%s' "${1##*.}" | tr 'A-Z' 'a-z')" in
    png)         printf 'image/png' ;;
    jpg|jpeg)    printf 'image/jpeg' ;;
    gif)         printf 'image/gif' ;;
    svg)         printf 'image/svg+xml' ;;
    webp)        printf 'image/webp' ;;
    avif)        printf 'image/avif' ;;
    bmp)         printf 'image/bmp' ;;
    ico)         printf 'image/x-icon' ;;
    *)           printf '' ;;
  esac
}


# params: target CSS file
# concatenates github-markdown.css and print.css, resolves the placeholders
#---------------------------------------------------------------
function buildCss {
#---------------------------------------------------------------
  local css="$1"
  local font_family_decl=""

  [ -n "$FONT_FAMILY" ] && font_family_decl="font-family: ${FONT_FAMILY};"

  cat "${RES_DIR}/github-markdown.css" > "$css" ||
    fail "$(printf "could not read %s/github-markdown.css." "$RES_DIR")"
  PAGE_SIZE="$PAGE_SIZE" PAGE_MARGIN="$PAGE_MARGIN" FONT_SIZE="$FONT_SIZE" \
  FONT_FAMILY_DECL="$font_family_decl" \
    perl -pe 's/__PAGE_SIZE__/$ENV{PAGE_SIZE}/g;
              s/__PAGE_MARGIN__/$ENV{PAGE_MARGIN}/g;
              s/__FONT_SIZE__/$ENV{FONT_SIZE}/g;
              s/__FONT_FAMILY_DECL__/$ENV{FONT_FAMILY_DECL}/g;' \
      "${RES_DIR}/print.css" >> "$css" ||
    fail "$(printf "could not read %s/print.css." "$RES_DIR")"
}


# params: HTML page to print, target PDF
#---------------------------------------------------------------
function printPdf {
#---------------------------------------------------------------
  local page="$1" pdf="$2"
  local log="${WORK_DIR}/chrome.log"
  local -a sandbox=()
  local pid waited=0 stable=0 size size_before=""

  [ "$NO_SANDBOX" -eq 1 ] && sandbox=(--no-sandbox)

  printf "Printing with %s ...\n" "$(basename "$CHROME")"
  rm -f "$pdf"

  # No --user-data-dir on purpose: with a profile directory of its own Chrome
  # writes the PDF but then does not exit any more.
  "$CHROME" --headless \
            --disable-gpu \
            --no-pdf-header-footer \
            --hide-scrollbars \
            --force-color-profile=srgb \
            --no-first-run \
            --no-default-browser-check \
            --disable-extensions \
            --disable-background-networking \
            --disable-sync \
            "${sandbox[@]}" \
            --virtual-time-budget=30000 \
            --run-all-compositor-stages-before-draw \
            --print-to-pdf="$pdf" \
            "file://${page}" > "$log" 2>&1 &
  pid=$!

  # Chrome usually exits within seconds. Should it stay alive anyway, end it as
  # soon as the PDF has stopped growing, so that a build never hangs.
  while kill -0 "$pid" 2> /dev/null; do
    sleep 1
    waited=$((waited + 1))
    if [ -s "$pdf" ]; then
      size="$(wc -c < "$pdf" | tr -d ' ')"
      if [ "$size" = "$size_before" ]; then
        stable=$((stable + 1))
      else
        stable=0
      fi
      size_before="$size"
      if [ "$stable" -ge 3 ]; then
        kill "$pid" 2> /dev/null
        break
      fi
    fi
    if [ "$waited" -ge "$CHROME_TIMEOUT" ]; then
      kill "$pid" 2> /dev/null
      warn "$(printf "%s did not finish within %s seconds." "$(basename "$CHROME")" "$CHROME_TIMEOUT")"
      break
    fi
  done
  wait "$pid" 2> /dev/null

  # Chrome logs harmless errors of components a print job does not need, so
  # the result itself decides whether the run was a success
  if [ ! -s "$pdf" ]; then
    [ -s "$log" ] && cat >&2 "$log"
    fail "$(printf "%s did not produce a PDF." "$(basename "$CHROME")")"
  fi
}


#---------------------------------------------------------------
function main {
#---------------------------------------------------------------
  local md="" pdf="" title="" keep_html=0 html page css
  NO_SANDBOX=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -o|--output) shift; [ "$#" -gt 0 ] || fail "-o needs a file name."; pdf="$1" ;;
      -t|--title) shift; [ "$#" -gt 0 ] || fail "-t needs a title."; title="$1" ;;
      --no-embed) EMBED_IMAGES="false" ;;
      --keep-html) keep_html=1 ;;
      --ci) NO_SANDBOX=1 ;;
      -h|--help) usage; exit 0 ;;
      -*) usage >&2; fail "$(printf "unknown option %s." "$1")" ;;
      *) md="$1" ;;
    esac
    shift
  done

  [ -n "$CI" ] && NO_SANDBOX=1
  [ "$(id -u)" = "0" ] && NO_SANDBOX=1

  if [ -z "$md" ]; then
    md="${REPO_DIR}/${MD_FILE_DEFAULT}"
    [ -n "$pdf" ] || pdf="${REPO_DIR}/${PDF_FILE_DEFAULT}"
  fi
  [ -f "$md" ] || fail "$(printf "%s is not a file." "$md")"
  [ -n "$pdf" ] || pdf="${md%.*}.pdf"
  mkdir -p "$(dirname "$pdf")" || fail "$(printf "could not create %s." "$(dirname "$pdf")")"
  pdf="$(cd "$(dirname "$pdf")" && pwd)/$(basename "$pdf")"

  checkPrerequisites curl perl openssl
  findChrome

  local file
  for file in github-markdown.css print.css template.html; do
    [ -f "${RES_DIR}/${file}" ] || fail "$(printf "%s/%s is missing." "$RES_DIR" "$file")"
  done

  WORK_DIR="${TMPDIR:-/tmp}/make_pdf.$$"
  mkdir -p "$WORK_DIR" || fail "$(printf "could not create %s." "$WORK_DIR")"
  trap 'rm -rf "$WORK_DIR"' EXIT

  writeHelpers

  html="${WORK_DIR}/body.html"
  page="${WORK_DIR}/page.html"
  css="${WORK_DIR}/style.css"

  renderMarkdown "$md" "$html"
  perl "${WORK_DIR}/postprocess.pl" "$RES_DIR" < "$html" > "${html}.done" &&
    mv "${html}.done" "$html" ||
    fail "could not post process the HTML of the Markdown API."

  if [ "$EMBED_IMAGES" = "true" ]; then
    embedImages "$(cd "$(dirname "$md")" && pwd)" "$html"
  fi

  [ -n "$title" ] || title="$(perl "${WORK_DIR}/title.pl" < "$html")"
  [ -n "$title" ] || title="$(basename "$md")"

  buildCss "$css"
  PDF_TITLE="$title" PDF_LANG="$HTML_LANG" \
    perl "${WORK_DIR}/assemble.pl" "${RES_DIR}/template.html" "$css" "$html" > "$page" ||
    fail "could not assemble the HTML page."

  printPdf "$page" "$pdf"

  if [ "$keep_html" -eq 1 ]; then
    cp "$page" "${pdf%.pdf}.html" &&
      printf "Kept the HTML in %s\n" "${pdf%.pdf}.html"
  fi

  printf "Created %s (%s bytes)\n" "$pdf" "$(wc -c < "$pdf" | tr -d ' ')"
}

main "$@"
