#!/usr/bin/env bash

# workspace-name: Astro (template, production build)

# Installed by the Astro plugin (plugins.sh --install astro); __WORKSPACE__ is the workspace it was installed into.
#
# Build an Astro site in a container: a template, made into the project with the latest Astro, at
# https://<name>.ddev.site. With --install the site is built (astro build) and the build is
# served there (astro preview). An Astro site is static: it has no accounts.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# The template the site is made from: one of Astro's own (blog, basics, minimal, …), or a
# repository on GitHub (user/repository).
site_template="blog";

# Distribution.
distribution_name="astro";
distribution_title="Astro";
distribution_webroot="";

ARGPARSE_DESCRIPTION="Build an ${distribution_title} project in __WORKSPACE__"
# The args file comes with the plugin: core/scripts/plugins/astro/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/astro/args/arg-astro.sh || exit 1 ;

shift $#;

astro_build ;
