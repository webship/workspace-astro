#!/usr/bin/env bash

# Astro for the Webship Workspace: make a site from a template, build it to a production build,
# serve it, run the Astro CLI on it, and wire its step pack into the testing setup.
#
# Placed by `plugins.sh --install astro` in core/scripts/plugins/astro/functions/, where
# bootstrap sources it after the core's own functions. Everything runs in the project's container
# (DDEV by default), never on the host: the site is a Node.js project in the project's site/
# folder, the web container builds it and serves the build as a daemon (`astro preview`), and the
# router serves that at the project's address. There is no database.
#
# An Astro site is static: it has no accounts. Astro is not a PHP platform and DDEV has no
# project type for it, so an Astro project is recognised by a file (.ddev/config.astro.yaml,
# written by the builder), and four names are the ones the core's tools look for:
#   set_astro_users          an empty list: there are no accounts  (cmd-tools-add-users.sh <project> astro)
#   add_astro_users          says so, and adds nothing             (the same tool)
#   cancel_astro_users       says so, and removes nothing          (cmd-tools-cancel-users.sh <project> astro)
#   testing_configure_astro  the step pack in the testing stack    (cmd-tools-testing.sh <project>)

# The step pack an Astro project is tested with, and the release line it is required at.
readonly ASTRO_STEPS_PACKAGE='@webship-js/astro-steps';
readonly ASTRO_STEPS_VERSION='^2.0.2';

# The package that makes a new site from a template, run with npm in the container.
readonly ASTRO_CREATE_PACKAGE='astro@latest';

# Where the site lives in the web container, and the port its server listens on.
readonly ASTRO_SITE='/var/www/html/site';
readonly ASTRO_PORT='4321';

# A static site has no accounts: the list is empty.
function set_astro_users() {
  users=();
}

# Is this folder an Astro project? The builder leaves .ddev/config.astro.yaml in it.
function astro_is_project() {
  local project_path="$1";
  [ -f "${project_path}/.ddev/config.astro.yaml" ] ;
}

# Go to the project a tool was asked about, or say why not.
function astro_enter_project() {
  local project_path="${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}";
  if [ ! -d "${project_path}" ] ; then
    echo "No project ${PROJECT_NAME} in ${WORKSPACE_ROOT}/${doc_name}." ;
    return 1 ;
  fi
  if ! astro_is_project "${project_path}" ; then
    echo "${doc_name}/${PROJECT_NAME} is not an Astro project (it has no .ddev/config.astro.yaml)." ;
    return 1 ;
  fi
  cd "${project_path}" || return 1 ;
}

# What the container tool is told about the site: the router sends the project's address to the
# server of the built site, which the web container runs as a daemon once there is a build, and
# Node.js is in the web image itself. The container tool installs the Node.js of the project when
# the container starts, after the daemons have started and within a short time limit: baked into
# the image, the Node.js the site was built with is there before anything starts, on every
# restart, on a slow connection and offline.
function astro_write_ddev_config() {
  local project_path="$1" nodejs_version="$2";
  mkdir -p "${project_path}/.ddev/web-build" || return 1 ;
  cat > "${project_path}/.ddev/config.astro.yaml" <<YAMLEOF
# Astro in this project. Written by the Astro builder of the workspace; build again rather than
# editing by hand. The web container serves no files of its own: the router sends ports 80 and
# 443 of the project's address to the server of the built site (astro preview), which the web
# container runs as a daemon once the site has a production build (site/dist). The server answers
# for the host names of the project only, which the container tool hands it in DDEV_HOSTNAME.
web_environment:
  - ASTRO_TELEMETRY_DISABLED=1
web_extra_exposed_ports:
  - name: astro
    container_port: ${ASTRO_PORT}
    http_port: 80
    https_port: 443
web_extra_daemons:
  - name: astro
    command: "bash -c 'while [ ! -f ${ASTRO_SITE}/dist/index.html ]; do sleep 2; done; cd ${ASTRO_SITE} && exec npx astro preview --port ${ASTRO_PORT} --host 0.0.0.0 --allowed-hosts \$DDEV_HOSTNAME'"
    directory: /var/www/html
YAMLEOF
  cat > "${project_path}/.ddev/web-build/Dockerfile.astro" <<DOCKEREOF
# Node.js ${nodejs_version} in the web image, so the site's server has it before the container's
# daemons start. Written by the Astro builder of the workspace.
RUN N_PREFIX=/usr/local n install ${nodejs_version} && node --version
DOCKEREOF
}

# A template that writes a sitemap or a feed carries a placeholder for the address of the site
# (site: 'https://example.com'). It becomes the address of the project, so the sitemap and the
# feed name pages that exist; a configuration that was already changed is left alone.
function astro_set_site_address() {
  local project_path="$1" base_url="$2" config ;
  for config in "${project_path}"/site/astro.config.mjs "${project_path}"/site/astro.config.ts "${project_path}"/site/astro.config.js ; do
    [ -f "${config}" ] || continue ;
    if grep -q "site: 'https://example.com'" "${config}" ; then
      sed -i "s#site: 'https://example.com'#site: '${base_url}'#" "${config}" \
        && echo "The address of the site in $(basename "${config}") is ${base_url}." ;
    fi
  done
}

# npm and the Astro CLI in the container, in the folder of the site.
function astro_npm() {
  ddev exec -d "${ASTRO_SITE}" "npm $*" ;
}

function astro_cli() {
  ddev exec -d "${ASTRO_SITE}" "npx astro $*" ;
}

# The release of Astro the site has installed.
function astro_version() {
  ddev exec "node -p \"require('${ASTRO_SITE}/node_modules/astro/package.json').version\"" 2>/dev/null | tr -d '\r' ;
}

# Wait until the server of the built site answers on its own port.
function astro_wait() {
  local attempt ;
  for attempt in $(seq 1 60) ; do
    if ddev exec "curl -fsS -o /dev/null http://127.0.0.1:${ASTRO_PORT}/" > /dev/null 2>&1 ; then
      return 0 ;
    fi
    sleep 2 ;
  done
  echo "The server of the built site did not start; what it said:" ;
  ddev exec "supervisorctl tail webextradaemons:astro stderr" 2>/dev/null ;
  return 1 ;
}

# Start the server of the built site again (the daemon of the web container), and wait for it.
function astro_restart() {
  if [ ! -f site/dist/index.html ] ; then
    echo "The site has no production build yet (site/dist): build it with --build." ;
    return 1 ;
  fi
  ddev exec "supervisorctl restart webextradaemons:astro" || return 1 ;
  astro_wait ;
}

# Build the site to a production build, and serve the new build.
function astro_production_build() {
  echo "Building the site to a production build (astro build)." ;
  astro_npm run build || { echo "The build of the site failed." ; return 1 ; } ;
  astro_restart ;
}

# Build an Astro site from nothing: the container, the template, its packages, and with --install
# the production build, served.
function astro_build() {
  trim_project_name ;
  local base_url="https://${PROJECT_NAME}.ddev.site" ;
  local template="${TEMPLATE:-${site_template:-blog}}" ;
  local project_path="${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}" ;

  cd ${WORKSPACE_ROOT}/${doc_name} || exit 1 ;

  drop_database ;
  rm -rf "${PROJECT_NAME}" ;
  mkdir -p "${PROJECT_NAME}" ;
  cd "${project_path}" || exit 1 ;

  # A generic web server and no database: the site is files, built once and served.
  ddev config --project-type=generic --webserver-type=generic --docroot="" --project-name=${PROJECT_NAME} \
    --omit-containers=db --nodejs-version=$(ddev_nodejs_version) || exit 1 ;
  astro_write_ddev_config "${project_path}" "$(ddev_nodejs_version)" || exit 1 ;
  ddev_up start -y || exit 1 ;

  # Astro's own way to a new site, with every question answered: the template, no git repository,
  # no greeting. The packages are installed in a step of their own: the installer of the template
  # gives up after a short time on a slow connection, and says the site is ready all the same.
  echo "Making the site from the template ${template} with the latest Astro." ;
  ddev exec "npm create --yes ${ASTRO_CREATE_PACKAGE} site -- --template '${template}' --no-install --no-git --skip-houston --yes" \
    || { echo "The site could not be made from the template ${template}." ; exit 1 ; } ;
  [ -f "${project_path}/site/package.json" ] || { echo "The template ${template} made no site (there is no site/package.json)." ; exit 1 ; } ;
  astro_set_site_address "${project_path}" "${base_url}" ;

  echo "Installing the packages of the site. This takes a few minutes." ;
  astro_npm install --no-audit --no-fund || { echo "npm install failed in the site." ; exit 1 ; } ;

  [ "${ADD_USERS}" == 'yes' ] && echo "--add-users: an Astro site is static and has no accounts; nothing is added." ;

  if [ "${INSTALL}" == 'yes' ] ; then
    astro_production_build || exit 1 ;
    echo "${doc_name} ${PROJECT_NAME} has been built and is served: Astro $(astro_version).";
    echo "Go to ${base_url}";
  else
    echo "${doc_name} ${PROJECT_NAME} is ready to build: Astro $(astro_version).";
    echo "Build and serve it with: bash cmd-tools-astro-cli.sh ${PROJECT_NAME} --build   (or build with --install)";
  fi

  if [ "${LAUNCH}" == 'yes' ] ; then
    ddev launch ;
  fi

  cd ${WORKSPACE_ROOT}/${doc_name};
}

# A static site has no accounts: there is nothing to add, and nothing to remove.
function add_astro_users() {
  echo "An Astro site is static: it has no accounts, so there are none to add." ;
}

function cancel_astro_users() {
  echo "An Astro site is static: it has no accounts, so there are none to remove." ;
}

# What cmd-tools-astro-cli.sh does: the first of --run, --build, --update, --restart that was
# asked for; with none of them, what the site is.
function astro_cli_tool() {
  trim_project_name ;
  astro_enter_project || exit 1 ;

  if ! ddev describe -j 2>/dev/null | grep -q '"status":"running"' ; then
    ddev start -y || exit 1 ;
  fi

  if [ ! "${RUN}" == '_none_' ] ; then
    # Unquoted on purpose: --run "info --clipboard" is a command and its arguments.
    astro_cli ${RUN} ;
    exit $? ;
  fi

  if [ "${BUILD}" == 'yes' ] ; then
    astro_production_build || exit 1 ;
    echo "Astro $(astro_version): the new build is served at https://${PROJECT_NAME}.ddev.site" ;
  elif [ "${UPDATE}" == 'yes' ] ; then
    echo "Astro $(astro_version) is installed." ;
    astro_npm update --no-audit --no-fund || exit 1 ;
    astro_production_build || exit 1 ;
    echo "Astro $(astro_version): the new build is served at https://${PROJECT_NAME}.ddev.site" ;
  elif [ "${RESTART}" == 'yes' ] ; then
    astro_restart || exit 1 ;
    echo "Astro $(astro_version): the build is served at https://${PROJECT_NAME}.ddev.site" ;
  else
    echo "${doc_name}/${PROJECT_NAME}: Astro $(astro_version) at https://${PROJECT_NAME}.ddev.site" ;
    echo "" ;
    if [ -f site/dist/index.html ] ; then
      echo "Production build: site/dist, $(find site/dist -name '*.html' | wc -l) pages, built $(date -r site/dist/index.html '+%Y-%m-%d %H:%M')" ;
      if ddev exec "curl -fsS -o /dev/null http://127.0.0.1:${ASTRO_PORT}/" > /dev/null 2>&1 ; then
        echo "Server: running (astro preview)" ;
      else
        echo "Server: not answering; start it again with --restart" ;
      fi
    else
      echo "Production build: none yet; build it with --build" ;
    fi
    echo "Accounts: none (a static site)" ;
  fi
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# The step pack in the testing stack of an Astro project. The core's testing_configure calls this
# in the project folder once webship-js is scaffolded and before the dependencies are installed;
# for a project that is not Astro it changes nothing.
#
# It adds the pack to package.json, lists its step definitions in cucumber.js after webship-js's
# own, and writes a first feature when the project has none of its own. There is no users
# registry: the site has no accounts. Every part is skipped when it is already there, so a second
# run adds what the first missed and never resets a suite. The suite is the project's (its
# package.json, cucumber.js and tests/ are next to site/, not in it).
function testing_configure_astro() {
  local project_path="$1";
  astro_is_project "${project_path}" || return 0 ;
  if [ ! -f "${project_path}/cucumber.js" ] || [ ! -f "${project_path}/package.json" ] ; then
    echo "  Astro: cucumber.js is not here yet — run the testing setup again once webship-js is scaffolded." ;
    return 1 ;
  fi

  echo "Adding the Astro step pack (${ASTRO_STEPS_PACKAGE} ${ASTRO_STEPS_VERSION}).";

  python3 - "${project_path}" "${ASTRO_STEPS_PACKAGE}" "${ASTRO_STEPS_VERSION}" <<'PYEOF' || return 1
import json, re, sys

project, pack, version = sys.argv[1:4]

# package.json: the pack as a dev dependency, at the release line this plugin was proven on.
pkg_file = project + '/package.json'
pkg = json.load(open(pkg_file))
if pack not in pkg.get('dependencies', {}) and pack not in pkg.get('devDependencies', {}):
    pkg.setdefault('devDependencies', {})[pack] = version
    open(pkg_file, 'w').write(json.dumps(pkg, indent=2) + '\n')
    print('  package.json: %s %s' % (pack, version))

# cucumber.js: the pack's step definitions after webship-js's own.
cucumber_file = project + '/cucumber.js'
src = open(cucumber_file).read()
before = src

if ('node_modules/%s/' % pack) not in src:
    line = "'node_modules/%s/tests/step-definitions/**/*.js'," % pack
    core = re.search(r"^([ \t]*)'node_modules/webship-js/tests/step-definitions/[^']*',.*$", src, re.M)
    opening = re.search(r"^([ \t]*)require:[ \t]*\[[ \t]*$", src, re.M)
    if core:
        src = src[:core.end()] + '\n' + core.group(1) + line + src[core.end():]
    elif opening:
        src = src[:opening.end()] + '\n' + opening.group(1) + '  ' + line + src[opening.end():]
    else:
        sys.exit("  cucumber.js has no require list this can add to. Add this line to it:\n    " + line)
    print('  cucumber.js: the step definitions of %s' % pack)

if src != before:
    open(cucumber_file, 'w').write(src)
PYEOF

  # A first feature, when the project has none for the site yet: the front page as a production
  # build, the pages in its navigation, its sitemap and feed, and an address with no page.
  local feature="${WORKSPACE_SCRIPTS}/plugins/astro/site.feature" ;
  if [ -f "${feature}" ] && [ ! -f "${project_path}/tests/features/site.feature" ] ; then
    mkdir -p "${project_path}/tests/features" && cp "${feature}" "${project_path}/tests/features/site.feature" \
      && echo "  tests/features/site.feature: a first feature for the site" ;
  fi

  if [ ! -f "${project_path}/site/dist/index.html" ] ; then
    echo "  the site has no production build yet: build it (cmd-tools-astro-cli.sh ${PROJECT_NAME} --build) before the suite runs" ;
  fi
}
