#!/usr/bin/env bash

# Installed by the Astro plugin (plugins.sh --install astro); __WORKSPACE__ is the workspace it was installed into.
#
# The Astro CLI for one Astro project of this workspace, in its container: say what the site
# is, run an Astro CLI command, build the site again, update its packages, start the server
# again. Nothing here runs on the host.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Distribution.
distribution_name="astro";

ARGPARSE_DESCRIPTION="Run the Astro CLI on an Astro project of __WORKSPACE__: status, a command, a build, an update, a restart"
# The args file comes with the plugin: core/scripts/plugins/astro/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/astro/args/arg-astro-cli.sh || exit 1 ;

shift $#;

astro_cli_tool ;
