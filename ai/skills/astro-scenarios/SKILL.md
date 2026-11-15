---
name: astro-scenarios
description: Write and run webship-js scenarios for an Astro site of the Webship Workspace with the Astro step pack (`@webship-js/astro-steps`) — the phrases of the pack by area (the production build, the navigation, the sitemap and the feed, images, islands, view transitions and the route announcer), what a site from the default template does and does not have, and the workspace command that runs them in the site's container against the build. Use when asked to "write a scenario for this Astro site", "test the navigation", "which step is there for the sitemap", "check that the page ships no JavaScript", or when a `.feature` file of an Astro project is being written or fixed.
argument-hint: '<site> [what to cover]'
---

# astro-scenarios

Scenarios for an Astro site of a Webship Workspace (`~/workspace`, container-based, DDEV by
default), written from the steps of [`@webship-js/astro-steps`](https://github.com/webship/astro-steps)
and of [webship-js](https://github.com/webship/webship-js) itself, and run in the site's container
by the workspace's own command. It comes with the Astro plugin (`@webship.co/workspace-astro`),
like the builder (`cmd-astro-project.sh`), the Astro CLI tool (`cmd-tools-astro-cli.sh`) and the
agents `astro-site-builder` and `astro-tester`.

## Where everything is

| What | Where |
| --- | --- |
| The site | `~/workspace/<folder>/<site>`, at `https://<site>.ddev.site` (`<folder>` is a sites folder: `dev`, `test`, `sandboxes`, `demos`) |
| The source of the site | `<site>/site/` (its own `package.json`, `astro.config.mjs`, `src/`) |
| What the address serves | The production build, `<site>/site/dist` |
| The suite's configuration | `<site>/cucumber.js`: the step definitions it loads. There is no users registry: the site has no accounts |
| The features | `<site>/tests/features/*.feature` (`site.feature` is the first one the setup wrote) |
| The pack's steps | `<site>/node_modules/@webship-js/astro-steps/tests/step-definitions/*.steps.js` |
| webship-js's steps | `<site>/node_modules/webship-js/tests/step-definitions/*.js` |
| The reports | `<site>/tests/reports/` |

## The order of work

1. **Make sure the testing stack is there.** From the sites folder:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site>
   ```
   It adds webship-js, the step pack and `tests/features/site.feature`. It is safe to run again:
   it adds what is missing and keeps what was changed.
2. **Make sure the build is the one you mean to test.** The suite tests the build, not the
   source:
   ```bash
   bash cmd-tools-astro-cli.sh <site>            # the version, the build and when it was made, the server
   bash cmd-tools-astro-cli.sh <site> --build    # after a change to the source
   ```
3. **Read the installed steps before writing a phrase.** They are the source of truth: the pack
   moves, and a phrase from memory is a guess.
   ```bash
   cd ~/workspace/<folder>/<site>
   grep -hE "^(Given|When|Then)\(" node_modules/@webship-js/astro-steps/tests/step-definitions/*.steps.js
   ```
   Every step carries a comment block with five examples above it; open the file when a phrase
   is not obvious.
4. **Look at the page first** (the Playwright MCP browser, a tab of your own): the titles, the
   link texts and the addresses are the site's own.
5. **Write the feature** in `<site>/tests/features/`, from phrases that exist (the lists below).
6. **Match every step without a browser**, then run the feature, then the suite:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site> --dry-run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --tags "@critical"
   bash cmd-tools-testing.sh <site> --run
   ```
   A dry run says `Undefined` for a phrase no definition matches: fix the phrase, do not write a
   step for it.

## No accounts

An Astro site is static: nobody logs in, and a scenario starts as a visitor
(`Given I am an anonymous user`, or straight at a page).

## The phrases, by area

Each line is a phrase the pack defines, and each one passed on a site built with
`bash cmd-astro-project.sh <site> --install` (the default template; the titles and the addresses
in quotes are that template's). Most `should` steps also take the negative.

### The build and its pages

```gherkin
Given I am on the homepage
Then the site should be a production build
Then the page should not ship JavaScript
Then the page should have scoped styles
Then the page title should end with "Astro Blog"
Then the page should not have any islands
```

### The navigation

```gherkin
Then I should see a navigation menu with the following links:
  | text  | path   |
  | Home  | /      |
  | About | /about |
```

### The sitemap and the feed

```gherkin
Then the sitemap should list "/"
Then the sitemap should list "/blog/first-post/"
Then the sitemap should not list "/this-page-does-not-exist/"
Then the RSS feed should be valid
Then the RSS feed at "/rss.xml" should be valid
Then the RSS feed should list "First post"
```

The sitemap and feed steps need a page of the site open first (`Given I am on the homepage`).

### Images

```gherkin
Given I am on "/blog/"
Then I should see an optimized image
Then every optimized image should have a width and a height
Then every optimized image should load lazily
Then all optimized images should be loaded
```

### View transitions and the route announcer

The default template has neither, and its negatives pass as it is built:

```gherkin
Then the page should not use view transitions
Then the page should not have a route announcer
Then the page "/about" should not be prefetched
```

The positives passed on the same site once the client router was added to its head component
(`<ClientRouter />` of `astro:transitions`) and the site was built again with
`bash cmd-tools-astro-cli.sh <site> --build`:

```gherkin
Then the page should use view transitions
Then the page should ship JavaScript
When I click the link "About" without a full page reload
Then the "astro:page-load" event should have fired
Then the "astro:after-swap" event should have fired
Then the last transition should have gone "forward"
Then the page should have a route announcer
Then the route announcer should announce "About Me"
When I go back without a full page reload
Then the last transition should have gone "back"
Then the "main" element should not have a view transition
```

`I am an anonymous user`, `I am on the homepage`, `I am on "/blog/"`, `I go to "/about/"`,
`I should see "<text>"` and `the response status code should be 200` are webship-js's own steps;
its status codes, links, landmarks and accessibility audits are used as they are and never
redefined for this platform.

## Traps found on a real site

- **The navigation table matches a link by a part of its text.** On the default template a row
  `| Blog | /blog |` fails with `href to contain "/blog" but got "/"`: the title of the site,
  `Astro Blog`, is a link to `/` in the same menu and is found first. Assert `Home` and `About`
  there, and the list of posts by its address (`Given I am on "/blog/"`).
- **`Then all navigation links should resolve` follows the links to other sites too.** The menu
  of the default template links to two social networks, which answered 403 to the suite. The
  suite depends on this site only: assert the links of the site by text and path.
- **`Then the 404 page should be available` fails on the default template**: it has no
  `src/pages/404.astro`, so the build writes no `404.html`. An address with no page still answers
  404, which is what to assert until the site has such a page:
  ```gherkin
  When I go to "/this-page-does-not-exist/"
  Then the response status code should be 404
  ```
- **`Then the optimized image should offer the "webp" format` fails on the default template**:
  its images are single `<img>` elements, and the step looks for a `<picture>` with a source of
  that type.
- **A title has a suffix only where the layout writes one.** On the default template the front
  page is `Astro Blog`, a post is its own title (`First post`) and the About page is `About Me`:
  `the page title should end with "Astro Blog"` passes on the front page only.
- **A stale build passes or fails for the wrong reason.** After a change to `site/src`, nothing
  changes at the address until `bash cmd-tools-astro-cli.sh <site> --build`.
- The steps for islands that hydrate, for elements kept across a navigation and for a page that
  is prefetched were not run on a site of this workspace: the default template has no island and
  no kept element. Run them on the site that has them before relying on them.

## Rules

- **No platform name in a step phrase.** A step says what a person does or sees: `the site should
  be a production build`, `the sitemap should list "/"`. The pack also has steps that name the
  generator of the page; a feature of this workspace leaves them out, and a custom step never
  names the product.
- **No account, no password, no secret in a feature file.** The site has no accounts, and a
  service it talks to is tested with its own pack on its own project.
- **No selector when a step says it**: `I should see an optimized image`, not a selector of the
  image.
- **The suite depends on this site only**, and changes nothing: a scenario reads the build, never
  writes into `site/`, and never builds.
- **A custom step is the last resort**: look in the pack and in webship-js first, write it in
  `<site>/tests/step-definitions/` with a comment block and examples, and say it may belong in
  the pack.
- **Everything runs in the container**, through `cmd-tools-testing.sh`. Never `npx cucumber-js`
  or `npx playwright` on the host.
- **A failing scenario is a result.** No `@wip`, no longer timeout, no looser assertion to turn a
  run green: say what the site did.

## Examples that run

`examples/` holds three features that pass on a site built with
`bash cmd-astro-project.sh <site> --install`. Copy one into the suite and run it:

```bash
cp ~/workspace/ai-skills/astro-scenarios/examples/built-pages.feature ~/workspace/<folder>/<site>/tests/features/
cd ~/workspace/<folder>
bash cmd-tools-testing.sh <site> --run --path tests/features/built-pages.feature
```

| Feature | What it shows |
| --- | --- |
| `examples/built-pages.feature` | The front page as a production build that ships no script, a page and a post at their addresses, what the template does not have, an address with no page |
| `examples/sitemap-and-feed.feature` | The sitemap listing the pages and the posts, the feed valid and listing a post |
| `examples/navigation-and-images.feature` | The menu asserted by text and path, and the optimized images of the list of posts |
