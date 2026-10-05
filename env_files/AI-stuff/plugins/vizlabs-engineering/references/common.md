Engineering development machines are running MacOS Tahoe or above.
The following utilities/services are installed: AWS-CLI, homebrew, rbenv, bash 5.0 or higher.
The following services are installed: mysql-server 8.0 or higher, memcached, redis 8 or higher

I am a devops engineer or software architect depending on which hat I'm wearing that day.

Our engineering team is small:
- 12 engineers total
- of those 3 are devops engineers
- Multiple engineers rarely work concurrently on the same project

Whenever writing shell scripts
- when I want to echo something to stderr, I prefer to use `>&2 echo` syntax.
- I prefer `if` statements to be  written with `if...; then` syntax instead of on separate lines.

Whenever writing code in any language prefer to use spaces instead of tabs when possible.
Use 2 spaces for each indentation level.

We use github for our version/source control system.

STRICT GITHUB RULES

Before connecting to a github repository to access files there:
- Prefer resolving paths directly instead of searching broadly. Avoid exploratory repo searches when the intended path is predictable.
- Ask clarifying questions before doing any repo scans if paths cannot be inferred or are ambiguous

Avoid exploratory searches when the path can be deterministically resolved.
Prefer a single correct path resolution over multiple search attempts.
Do NOT:
- search for directories that can be inferred
- issue multiple broad queries to locate standard or typical Rails paths (ruby-on-rails ONLY)

Behavior Expectations
- Prefer resolving paths directly instead of searching broadly
- Avoid exploratory repo searches when the intended path is predictable
- If multiple matches exist, prioritize the "rails application root" prefixed version (ruby-on-rails ONLY)

Path Resolution Algorithm
When given a file path:
1. If the path is already fully qualified (e.g. starts with a known top-level directory), use it as-is.
2. Otherwise, if the repository has a root mapping and the path starts with a standard Rails directory such as app/, lib/, config/, db/, spec/, or public/, prepend the mapped application root automatically.
3. Otherwise, if the repository has a root mapping and the user provides a path that is normally understood relative to the application root, prefer the mapped application root version first.
4. Only if the direct resolved path is not found, fall back to searching the repository.

Exceptions
If the user explicitly references a fully qualified path (e.g. starting with `/`) use that as-is

Tool use strategy (PRIORITY ORDER)
1. Use company knowledge first when available.
2. If knowledge does not contain the needed files, use the GitHub API.
3. When using the GitHub API:
   - Construct the full resolved path first
   - Attempt direct file access
   - Avoid search unless the path fails

Debug / Transparency (GitHub API Usage)
Before making any GitHub API call, explicitly state:
- The repository name
- The branch (if known)
- The fully resolved file path(s)
- The specific action being taken (e.g. fetch_file, search, etc.)

Format this as a short “DEBUG” message before the request. Example:

DEBUG:
Repo: vizmule_rails
Branch: temp_gpt
Action: fetch_file
Path: railsapp/lib/constraints/PageVanityurl.rb

Keep this concise but always include it when using the GitHub API.
After printing the DEBUG message, and before starting API requests wait 5 seconds to allow me time to cancel the query if DEBUG looks like it got it wrong.
Do not make a GitHub API call unless you have first printed the DEBUG block with the fully resolved path.

