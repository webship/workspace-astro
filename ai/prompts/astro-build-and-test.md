Make an Astro site from a template in a sites folder, serve its production build and prove it with its first webship-js feature.

```
claude --permission-mode bypassPermissions """
Build an Astro site named <name> in this sites folder and test it with webship-js
# ~/workspace/<dev|test|sandboxes|demos> · https://<name>.ddev.site · container-based (DDEV by default)
# the builder deletes a project of the same name first: stop if <name> is a site somebody still needs
# nothing on the host: no astro, node, npm or npx outside the site's container
# a static site: no database and no accounts, and none is added to make a tool happy

1. bash cmd-astro-project.sh <name> --install
   (add --template <blog|basics|minimal> for a template other than blog, the default)
2. bash cmd-tools-astro-cli.sh <name>
   tell me the version, the address, how many pages the production build has and whether the server runs
3. bash cmd-tools-testing.sh <name>
   webship-js, the step pack and tests/features/site.feature
4. bash cmd-tools-testing.sh <name> --dry-run --path tests/features/site.feature
5. bash cmd-tools-testing.sh <name> --run --path tests/features/site.feature
   the first feature fits the blog template: on another template, tell me which scenarios do not apply instead of changing them

If a command fails, show the line that failed and stop. Do not retry with other flags.
When the feature is green: the address, the version, how many scenarios and steps passed.
Then ask me whether to keep the site or remove it with: bash cmd-tools-remove.sh <name>
"""
```
