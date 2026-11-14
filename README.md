# @webship.co/workspace-astro

Astro for the [Webship Workspace](https://github.com/webship/workspace) dashboard: a builder that
makes a real Astro site from a template in a container, builds it to a production build and serves
it, an Astro CLI tool for the sites it built, the
[Astro step pack](https://github.com/webship/astro-steps) wired into the workspace's testing
setup, and two AI agents that know all of it.

The workspace is container-based (DDEV by default): an Astro project is a row like any other, so
the row menus the core draws (start, stop, launch, backup, clone, remove, tests) work on it; what
does not apply to a static site is listed under
[What is different from a PHP platform](#what-is-different-from-a-php-platform).

The plugin is made from the reference platform plugin,
[`@webship.co/workspace-wordpress`](https://github.com/webship/workspace-wordpress).

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require github:webship/workspace-astro   # npm install into the dashboard
bash core/scripts/plugins.sh --activate astro                            # plugins.astro in settings.yml
bash core/scripts/plugins.sh --install astro                             # commands, functions, args, agents
bash core/scripts/plugins.sh --configure astro                           # nothing to configure: it has no settings file
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page. `--install` is
idempotent. `--uninstall` removes what it placed; an agent you edited stays.

The commands land in the sites folders that are in the workspace (`dev`, `test`, `sandboxes`,
`demos`); the agents land in the AI Agents folder (`ai-agents/`) when the workspace has one, and are
installed into `~/.claude/agents` from there like any other agent.

The agents, the builder's flags in the Build form and the step pack in the testing setup need a
Webship Workspace after 1.0.6.

## What the package holds

| Path | What it is |
| --- | --- |
| `commands/cmd-astro-project.sh` | The builder, in the Build list as **Astro (template, production build)**, installed into every sites folder |
| `commands/cmd-tools-astro-cli.sh` | The Astro CLI for one project: what the site is, a command, a build, an update, a restart |
| `scripts/functions/fun-astro.sh` | The bash functions behind both, sourced by bootstrap once installed; the names the core's tools look for (`set_astro_users`, `add_astro_users`, `cancel_astro_users`, `testing_configure_astro`) |
| `scripts/args/arg-astro.sh`, `arg-astro-cli.sh` | Their argparse; the Build form draws the builder's flags from the first |
| `testing/site.feature` | The first feature an Astro project gets when testing is set up |
| `agents/astro-site-builder.md` | The agent that builds and maintains Astro sites with these commands |
| `agents/astro-tester.md` | The agent that writes and runs scenarios with the Astro step pack |
| `src/index.ts` | `register(api)`: what the assistant is told about Astro here |
| `features/astro.feature` | Scenarios for the dashboard's own browser suite |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.

## What is different from a PHP platform

Astro is a static site generator and DDEV has no project type for it. The plugin keeps the shape
of the reference and changes only this:

| | WordPress (the reference) | Astro |
| --- | --- | --- |
| Project | `--project-type=wordpress`, nginx and PHP | `--project-type=generic --webserver-type=generic`: no web server; the router sends the project's address to `astro preview`, which the web container runs as a daemon (`.ddev/config.astro.yaml`) |
| Recognised by | The DDEV project type | The file `.ddev/config.astro.yaml` |
| The site | The project folder | The Node.js project in the project's `site/` folder; the test suite is next to it, with a `package.json` of its own |
| Node.js | The workspace's (24), for the front-end tools | The workspace's (24), and baked into the web image (`.ddev/web-build/Dockerfile.astro`) so the server has it before the daemons start |
| Database | The container tool's default | None (`--omit-containers=db`) |
| Getting the code | `wp core download` | `npm create astro` with a template (the latest Astro, no git repository), then `npm install` |
| Install | `wp core install` | `astro build` (the production build in `site/dist`), then `astro preview`, which answers for the host names of the project only |
| Accounts | One per role | None: `set_astro_users` is an empty list, and the add and cancel functions say so |

What that means for the row menus of an Astro project:

| Menu | On an Astro project |
| --- | --- |
| Start, stop, restart, launch | Work: the server of the build starts with the container |
| Tests | Work: set up, run, reports |
| Remove, clone | Work |
| Back up this project | Archives the folder; the database export it also tries has nothing to export and says so |
| Export the database, import a database, snapshots | Do not apply: there is no database |
| Users (add or cancel the test users) | Does not apply: there are no accounts |

## The commands

Run them from a sites folder. `--help` is safe on both.

### Build a site

```bash
cd ~/workspace/dev
bash cmd-astro-project.sh mysite --install
```

| Flag | What it does |
| --- | --- |
| `--template <x>` | The template the site is made from: one of the templates of Astro (`blog`, the default; `basics`, `minimal`), or a repository on GitHub as `user/repository` |
| `--install` | Build the site to a production build and serve it |
| `--add-users` | Taken and ignored: a static site has no accounts |
| `--launch` | Open the site when it is ready |

The site answers at `https://mysite.ddev.site`. It is the Node.js project in `mysite/site`, and
what the address serves is its production build (`site/dist`): a change to the source shows after
the next build. Where the template carries the placeholder address `https://example.com` for its
sitemap and feed, the builder sets the address of the project there. A project of the same name is deleted first.

### Work on a site

```bash
bash cmd-tools-astro-cli.sh mysite                  # version, address, the build, the server
bash cmd-tools-astro-cli.sh mysite --build          # build again, and serve the new build
bash cmd-tools-astro-cli.sh mysite --update         # npm update in the site, then build and serve again
bash cmd-tools-astro-cli.sh mysite --run "info"     # any Astro CLI command
bash cmd-tools-astro-cli.sh mysite --restart        # start the server of the build again
```

### Test a site

```bash
bash cmd-tools-testing.sh mysite                 # webship-js, the step pack, a first feature
bash cmd-tools-testing.sh mysite --run           # run the suite in the container
bash cmd-tools-testing.sh mysite --run --path tests/features/site.feature
```

`cmd-tools-testing.sh` is the workspace's own. For an Astro project it also adds
`@webship-js/astro-steps` to `package.json`, lists its step definitions in `cucumber.js` after
webship-js's own, and places `tests/features/site.feature` when the project has none: the front
page as a production build, the pages in its navigation, its sitemap and its feed, and an address
with no page. There is no
users registry. Run it again and it adds what is missing and keeps what you changed.

## The agents

| Agent | Use it to |
| --- | --- |
| `astro-site-builder` | Make a site from a template, build it again, update, maintain or remove it with the commands above, in containers only |
| `astro-tester` | Set the testing stack up, look at the built site in the Playwright MCP browser first, write scenarios from the pack's steps and run them; it never creates an account in a suite and never writes a platform name into a step phrase |

After `--install` they are in the AI Agents folder of the dashboard; **Install** there puts one into
`~/.claude/agents`, or from the command line:

```bash
cd ~/workspace/ai-agents
bash cmd-tools-ai-items.sh astro-tester --install
```

## Develop it

```bash
npm install     # builds dist/ (TypeScript)
npm run lint
npm test        # the manifest, the commands, the agents, the functions against a scaffolded project
```
