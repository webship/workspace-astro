#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The name of the project: its folder, its DDEV project and its host name.')
parser.add_argument('-t', '--template',
                    default="${site_template}",
                    help='The template the site is made from: one of the templates of Astro (blog, basics, minimal), or a repository on GitHub as user/repository. [default %(default)s]')
parser.add_argument('-i', '--install',
                    action='store_true',
                    default=False,
                    help='Build the site (astro build) and serve the build at the address of the project (astro preview).')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='Taken so that every builder accepts the same flags: a static site has no accounts, and nothing is added.')
parser.add_argument('-l', '--launch',
                    action='store_true',
                    default=False,
                    help='Open the site in a browser when it is ready.')
ARGEOF
